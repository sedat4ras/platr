"""
Platr Backend — Comment Moderation Service.
[FastAPIDBAgent | BE-002]

Two-layer moderation strategy (cost-optimised):

  Layer 1 — Inline (every new comment, synchronous, free):
    Keyword scan against a hard-blocked list.
    Catches obvious slurs, threats, and spam instantly.
    No API calls, no latency.

  Layer 2 — Agent (on-demand, async, Claude):
    ModerationAgent in agents/moderation_agent.py.
    Triggered via POST /admin/run-moderation-agent.
    Only reviews comments that have been reported by at least one user.
    Claude evaluates each with nuanced judgment via tool use.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass

logger = logging.getLogger(__name__)

# ── Hard-blocked keywords (Layer 1) ──────────────────────────────────────────
# Covers obvious threats, slurs, and spam. Case-insensitive, substring match.
_HARD_BLOCKED: list[str] = [
    # Self-harm / threats
    "kill yourself", "kys", "go die", "end yourself", "kill urself",
    # Violence
    "bomb", "terrorist", "shoot", "stab", "i will kill",
    # Common slurs & insults
    "retard", "faggot", "nigger", "nigga", "cunt",
    "moron", "idiot", "fuck", "fucker", "fucking", "fuckhead",
    # Spam
    "click here", "buy now", "free money", "visit this site", "dm me for",
    # Doxxing / Personal info (Guideline 5.1.2 — prevent plate-to-person identification)
    "lives at", "home address", "his address", "her address", "their address",
    "phone number is", "mobile number", "call them at", "call him at", "call her at",
    "real name is", "full name is", "i know where", "i know who",
    "found their house", "found his house", "found her house",
    "license belongs to", "plate belongs to", "owner is", "registered to",
]


@dataclass
class ModerationResult:
    is_appropriate: bool
    reason: str
    warning_message: str | None


def moderate_comment(body: str) -> ModerationResult:
    """
    Layer 1 — synchronous keyword scan.

    Called inline on every new comment. Zero latency, zero cost.
    Subtle/context-dependent content is handled by the ModerationAgent (Layer 2)
    which only reviews comments reported by the community.
    """
    return _keyword_scan(body)


def _keyword_scan(body: str) -> ModerationResult:
    """Case-insensitive substring scan against the hard-blocked list."""
    body_lower = body.lower()
    for phrase in _HARD_BLOCKED:
        if phrase in body_lower:
            logger.info(f"[Moderation] Blocked keyword '{phrase}' in comment")
            return ModerationResult(
                is_appropriate=False,
                reason=f"Contains blocked phrase: '{phrase}'",
                warning_message=_warning_message(),
            )
    return ModerationResult(is_appropriate=True, reason="OK", warning_message=None)


def _warning_message() -> str:
    return (
        "Yorumunuz topluluk kurallarımıza aykırı içerik barındırdığından "
        "gizlendi. Lütfen saygılı ve yapıcı bir dil kullanın."
    )
