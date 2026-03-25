"""
Platr — Moderation Agent
[ModerationAgent | LangGraph + Claude Tool Use]

A LangGraph StateGraph agent that uses Claude (claude-haiku-4-5) with tool use
to review all visible comments and hide aggressive/inappropriate ones.

Graph topology:
  START → fetch_comments → claude_review → apply_decisions → END

Claude is given a single tool: hide_comment(comment_id, reason)
It calls this tool for every comment it finds inappropriate.

Usage (CLI):
  python -m agents.moderation_agent

Usage (from FastAPI):
  from agents.moderation_agent import run_moderation_agent
  result = await run_moderation_agent()
"""

from __future__ import annotations

import asyncio
import json
import logging
import os
import uuid
from typing import Annotated, TypedDict

import anthropic
import asyncpg
import operator
from langgraph.graph import END, START, StateGraph

# Load .env if present (for CLI usage)
try:
    from dotenv import load_dotenv
    load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", ".env"))
    load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", "backend", ".env"))
except ImportError:
    pass

logger = logging.getLogger(__name__)

# asyncpg needs plain "postgresql://" — strip SQLAlchemy's "+asyncpg" driver prefix if present
_DB_URL = os.getenv("DATABASE_URL", "postgresql://platr:platr@localhost:5432/platr").replace(
    "postgresql+asyncpg://", "postgresql://"
)

# ── Claude tool definition ─────────────────────────────────────────────────────

_HIDE_TOOL: dict = {
    "name": "hide_comment",
    "description": (
        "Hide an inappropriate comment from public view on Platr. "
        "Call this for every comment that violates community standards."
    ),
    "input_schema": {
        "type": "object",
        "properties": {
            "comment_id": {
                "type": "string",
                "description": "UUID of the comment to hide",
            },
            "reason": {
                "type": "string",
                "description": "One-sentence reason why this comment is inappropriate",
            },
        },
        "required": ["comment_id", "reason"],
    },
}

_SYSTEM_PROMPT = """
You are the Platr Moderation Agent — an autonomous content moderator for a
car-spotting community app in Victoria, Australia.

These comments have already been flagged by at least one community member.
Your job: decide which ones genuinely violate community standards.

HIDE comments containing:
• Direct harassment or personal attacks on individuals
• Slurs, hate speech, or discriminatory language
• Threats of violence or self-harm encouragement
• Explicit sexual content
• Spam, scam links, or commercial solicitation

KEEP comments containing:
• Car discussions, opinions, and technical talk
• Mild frustration (e.g. "that driver is hopeless")
• Australian slang and casual language
• Criticism of driving behaviour (without targeted personal attacks)
• General community chat about plates/cars

Be fair — a report doesn't automatically mean a comment is wrong.
Call hide_comment only for comments that clearly violate the rules above.
For appropriate comments, do nothing. When done reviewing all, stop.
"""


# ── Shared state ──────────────────────────────────────────────────────────────

class ModerationState(TypedDict):
    comments:        list[dict]                             # [{id, body}]
    hidden_ids:      Annotated[list[str], operator.add]     # UUIDs Claude flagged
    hidden_reasons:  Annotated[list[str], operator.add]     # matching reasons
    summary:         str


# ── Node 1: Fetch only reported comments from DB ──────────────────────────────

async def fetch_comments_node(state: ModerationState) -> dict:
    """
    Pull only visible comments that have been reported by at least one user.

    Layer 2 philosophy: the community acts as a first-pass filter.
    Claude only spends tokens on comments humans have already flagged.
    reported_by is a PostgreSQL TEXT[] — array_length(...) > 0 means at least 1 report.
    """
    conn = await asyncpg.connect(_DB_URL)
    try:
        rows = await conn.fetch(
            "SELECT id::text, body, array_length(reported_by, 1) AS report_count "
            "FROM comments "
            "WHERE deleted_at IS NULL "
            "  AND is_hidden = false "
            "  AND array_length(reported_by, 1) >= 1 "
            "ORDER BY array_length(reported_by, 1) DESC, created_at ASC"
        )
        comments = [
            {"id": row["id"], "body": row["body"], "reports": row["report_count"]}
            for row in rows
        ]
    finally:
        await conn.close()

    logger.info(
        f"[ModerationAgent] Fetched {len(comments)} reported comment(s) for review"
    )
    return {"comments": comments, "hidden_ids": [], "hidden_reasons": [], "summary": ""}


# ── Node 2: Claude reviews comments with tool use ─────────────────────────────

async def claude_review_node(state: ModerationState) -> dict:
    """
    Send all visible comments to Claude.
    Claude calls hide_comment() for each inappropriate one.
    We run the tool-use loop until Claude reaches end_turn.
    """
    comments = state["comments"]
    if not comments:
        return {"hidden_ids": [], "hidden_reasons": [], "summary": "No comments to review."}

    # Try settings first (loaded from .env), then fall back to raw env var
    try:
        from backend.config import settings
        api_key = settings.anthropic_api_key or os.getenv("ANTHROPIC_API_KEY", "")
    except Exception:
        api_key = os.getenv("ANTHROPIC_API_KEY", "")

    if not api_key:
        logger.error("[ModerationAgent] ANTHROPIC_API_KEY is not set — aborting")
        return {"hidden_ids": [], "hidden_reasons": [], "summary": "Error: ANTHROPIC_API_KEY not set."}

    client = anthropic.AsyncAnthropic(api_key=api_key)

    # Build the user message — include report count so Claude weighs severity
    comment_list = "\n".join(
        f"[{c['id']}] (reports: {c.get('reports', 1)}) {c['body']}"
        for c in comments
    )
    messages: list[dict] = [
        {
            "role": "user",
            "content": (
                f"Please review the following {len(comments)} reported comment(s). "
                f"Each has been flagged by at least one community member. "
                f"Call hide_comment for those that genuinely violate the rules:\n\n"
                f"{comment_list}"
            ),
        }
    ]

    hidden_ids: list[str] = []
    hidden_reasons: list[str] = []

    # ── Agentic tool-use loop ──────────────────────────────────────────────────
    while True:
        response = await client.messages.create(
            model="claude-haiku-4-5-20251001",
            max_tokens=1024,
            system=_SYSTEM_PROMPT,
            tools=[_HIDE_TOOL],
            messages=messages,
        )

        logger.info(f"[ModerationAgent] Claude stop_reason={response.stop_reason}")

        # Collect any hide_comment tool calls
        tool_results: list[dict] = []
        for block in response.content:
            if block.type == "tool_use" and block.name == "hide_comment":
                cid    = str(block.input.get("comment_id", ""))
                reason = str(block.input.get("reason", ""))
                hidden_ids.append(cid)
                hidden_reasons.append(reason)
                logger.info(f"[ModerationAgent] → Flagging {cid[:8]}…: {reason}")
                tool_results.append({
                    "type":        "tool_result",
                    "tool_use_id": block.id,
                    "content":     f"Comment {cid} queued for hiding.",
                })

        # Claude is done
        if response.stop_reason == "end_turn":
            break

        # Feed tool results back and continue the loop
        if response.stop_reason == "tool_use" and tool_results:
            messages.append({"role": "assistant", "content": response.content})
            messages.append({"role": "user",      "content": tool_results})
        else:
            break

    return {"hidden_ids": hidden_ids, "hidden_reasons": hidden_reasons, "summary": ""}


# ── Node 3: Apply Claude's decisions to the DB ────────────────────────────────

async def apply_decisions_node(state: ModerationState) -> dict:
    """Set is_hidden=true for every comment Claude flagged."""
    hidden_ids = state.get("hidden_ids", [])
    total      = len(state.get("comments", []))

    if not hidden_ids:
        summary = (
            f"Reviewed {total} comment(s) — all appropriate, nothing hidden."
        )
        return {"summary": summary}

    conn = await asyncpg.connect(_DB_URL)
    actually_hidden: list[str] = []
    try:
        for cid in hidden_ids:
            try:
                await conn.execute(
                    "UPDATE comments SET is_hidden = true WHERE id = $1",
                    uuid.UUID(cid),
                )
                actually_hidden.append(cid)
            except Exception as e:
                logger.warning(f"[ModerationAgent] Could not hide {cid}: {e}")
    finally:
        await conn.close()

    reasons_map = dict(zip(hidden_ids, state.get("hidden_reasons", [])))
    hidden_detail = [
        {"id": cid, "reason": reasons_map.get(cid, "—")}
        for cid in actually_hidden
    ]

    summary = (
        f"Reviewed {total} comment(s). "
        f"Hidden {len(actually_hidden)}: "
        f"{json.dumps(hidden_detail, ensure_ascii=False)}"
    )
    logger.info(f"[ModerationAgent] Complete — {summary}")
    return {"summary": summary}


# ── Graph assembly ─────────────────────────────────────────────────────────────

def build_moderation_graph():
    """Compile the moderation StateGraph."""
    builder = StateGraph(ModerationState)

    builder.add_node("fetch",    fetch_comments_node)
    builder.add_node("moderate", claude_review_node)
    builder.add_node("apply",    apply_decisions_node)

    builder.add_edge(START,      "fetch")
    builder.add_edge("fetch",    "moderate")
    builder.add_edge("moderate", "apply")
    builder.add_edge("apply",    END)

    return builder.compile()


# ── Public API ─────────────────────────────────────────────────────────────────

async def run_moderation_agent() -> dict:
    """
    Invoke the moderation agent. Returns a result dict:
      {checked, hidden, hidden_ids, hidden_reasons, summary}
    """
    graph = build_moderation_graph()

    initial: ModerationState = {
        "comments":       [],
        "hidden_ids":     [],
        "hidden_reasons": [],
        "summary":        "",
    }

    final = await graph.ainvoke(initial)

    return {
        "checked":        len(final["comments"]),
        "hidden":         len(final["hidden_ids"]),
        "hidden_ids":     final["hidden_ids"],
        "hidden_reasons": final["hidden_reasons"],
        "summary":        final["summary"],
    }


# ── CLI entry point ────────────────────────────────────────────────────────────

if __name__ == "__main__":
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s  %(levelname)-8s  %(message)s",
    )

    result = asyncio.run(run_moderation_agent())

    print("\n" + "=" * 60)
    print("  PLATR MODERATION AGENT — COMPLETE")
    print("=" * 60)
    print(f"  Checked : {result['checked']}")
    print(f"  Hidden  : {result['hidden']}")
    if result["hidden_ids"]:
        for cid, reason in zip(result["hidden_ids"], result["hidden_reasons"]):
            print(f"    ✗ {cid[:8]}… — {reason}")
    else:
        print("    ✓ All comments are appropriate")
    print("=" * 60)
