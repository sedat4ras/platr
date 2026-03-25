"""
Platr Multi-Agent — Main Orchestrator (LangGraph StateGraph)
Wires all agents into a directed graph with conditional routing.

Graph topology:
  START → lead_agent → [backend_agent | ios_agent | osint_agent] → END
  Agents can hand back to lead for review/merge cycles.

Usage:
  python -m agents.orchestrator
"""

from __future__ import annotations

from langgraph.graph import StateGraph, START, END

from agents.state import PlatrState
from agents.lead_agent import lead_agent_node, lead_router
from agents.backend_agent import backend_agent_node
from agents.ios_agent import ios_agent_node
from agents.osint_agent import osint_agent_node


def build_graph() -> StateGraph:
    """Construct and compile the Platr multi-agent StateGraph."""

    builder = StateGraph(PlatrState)

    # ── Nodes ──────────────────────────────────────────────────────────────
    builder.add_node("lead_agent",    lead_agent_node)
    builder.add_node("backend_agent", backend_agent_node)
    builder.add_node("ios_agent",     ios_agent_node)
    builder.add_node("osint_agent",   osint_agent_node)

    # ── Entry edge ─────────────────────────────────────────────────────────
    builder.add_edge(START, "lead_agent")

    # ── Conditional routing from lead ──────────────────────────────────────
    builder.add_conditional_edges(
        "lead_agent",
        lead_router,
        {
            "backend": "backend_agent",
            "ios":     "ios_agent",
            "osint":   "osint_agent",
            "done":    END,
        },
    )

    # ── Each specialist returns to ios (parallel simulation) ───────────────
    builder.add_edge("backend_agent", "ios_agent")
    builder.add_edge("ios_agent",     "osint_agent")
    builder.add_edge("osint_agent",   END)

    return builder.compile()


def run_orchestrator() -> None:
    """Bootstrap the Platr project build via the multi-agent graph."""

    print("=" * 68)
    print("  🤖  PLATR MULTI-AGENT ORCHESTRATOR — LangGraph v0.2")
    print("=" * 68)

    graph = build_graph()

    initial_state: PlatrState = {
        "messages":      [],
        "current_agent": "lead",
        "task":          {},
        "artifacts":     {},
        "errors":        [],
        "final_output":  {},
    }

    final_state = graph.invoke(initial_state)

    print("\n" + "=" * 68)
    print("  ✅  BUILD COMPLETE")
    print(f"  Tamamlanan görevler: {final_state['task'].get('completed', [])}")
    print(f"  Hata sayısı:         {len(final_state.get('errors', []))}")
    print("=" * 68)

    return final_state


if __name__ == "__main__":
    run_orchestrator()
