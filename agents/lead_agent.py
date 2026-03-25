"""
Platr Multi-Agent — Lead Agent (Project Manager & Architecture Lead)
Coordinates the team, breaks down requirements, routes tasks, and enforces
Apple HIG + App Store Review compliance (especially UGC Rule 1.2).
"""

from __future__ import annotations
from langchain_core.messages import SystemMessage, HumanMessage
from agents.state import PlatrState


LEAD_SYSTEM_PROMPT = """
You are the Lead Agent and Architecture Lead for the Platr project.

RESPONSIBILITIES:
1. Decompose high-level requirements into atomic tasks.
2. Route tasks to: ios_agent, backend_agent, or osint_agent.
3. Merge code artifacts and resolve conflicts.
4. Enforce Apple Human Interface Guidelines (HIG) and App Store Review
   Guidelines — especially Guideline 1.2 (User-Generated Content):
   - Every comment/text field MUST expose a "Report" and "Block" button.
   - No photo-upload module anywhere in the app.
5. Verify Unique Constraint logic ([State]+[PlateText]) before merging DB schemas.
6. Sign off on VicRoads OSINT integration before shipping rego_check service.

ROUTING RULES:
- SwiftUI / MVVM / ZStack / iOS → route to ios_agent
- FastAPI / PostgreSQL / SQLAlchemy / REST → route to backend_agent
- VicRoads scraping / BeautifulSoup / Selenium / OSINT → route to osint_agent
- Conflict resolution / architecture decisions → handle yourself

OUTPUT FORMAT:
Always respond with a JSON action:
{
  "action": "route" | "merge" | "review" | "done",
  "target_agent": "ios_agent" | "backend_agent" | "osint_agent" | null,
  "task_description": "...",
  "artifact_key": "..."
}
"""


def lead_agent_node(state: PlatrState) -> PlatrState:
    """
    Entry node. Orchestrates the overall project flow.
    In a real LangGraph deployment this calls an LLM; here we demonstrate
    the deterministic bootstrap routing for the Platr initial build.
    """
    print("[LeadAgent] 🎯 Proje analiz ediliyor ve görevler dağıtılıyor...")

    initial_tasks = [
        {
            "id": "BE-001",
            "target": "backend",
            "description": "PostgreSQL schema: Plates, Users, Comments (with Unique Constraint on state+plate_text)",
            "priority": 1,
        },
        {
            "id": "iOS-001",
            "target": "ios",
            "description": "PlateTemplateRenderer: ZStack-based VIC plate renderer (Standard, Custom Black)",
            "priority": 1,
        },
        {
            "id": "OSINT-001",
            "target": "osint",
            "description": "VicRoads rego check scraper: async BeautifulSoup/Selenium fallback",
            "priority": 2,
        },
        {
            "id": "BE-002",
            "target": "backend",
            "description": "FastAPI routers: /plates, /users, /comments with duplicate-redirect logic",
            "priority": 2,
        },
        {
            "id": "iOS-002",
            "target": "ios",
            "description": "PlateView + AddPlateView + CommentView (Report/Block UGC compliance)",
            "priority": 3,
        },
    ]

    state["task"] = {"queue": initial_tasks, "completed": []}
    state["artifacts"] = {}
    state["errors"] = []
    state["current_agent"] = "backend"

    state["messages"] = list(state.get("messages", [])) + [
        SystemMessage(content=LEAD_SYSTEM_PROMPT),
        HumanMessage(
            content=(
                "[LeadAgent→All] Platr v1.0 build başlatıldı. "
                f"Toplam {len(initial_tasks)} görev kuyruğa alındı. "
                "BE-001 ve iOS-001 paralel olarak işleniyor."
            )
        ),
    ]

    print(f"[LeadAgent] ✓ {len(initial_tasks)} görev kuyruğa alındı")
    print("[LeadAgent] → FastAPIDBAgent: BE-001 (DB Schema)")
    print("[LeadAgent] → iOSSwiftAgent:  iOS-001 (PlateTemplateRenderer)")

    return state


def lead_router(state: PlatrState) -> str:
    """Conditional edge: decides which agent node to call next."""
    agent = state.get("current_agent", "done")
    print(f"[LeadAgent] 🔀 Yönlendirme: {agent}")
    return agent
