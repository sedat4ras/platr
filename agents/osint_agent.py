"""
Platr Multi-Agent — OSINT & Automation Agent (Data Scraper)
Responsible for: VicRoads rego check, BeautifulSoup/Selenium scraping,
background async polling, vehicle detail enrichment.
"""

from agents.state import PlatrState

OSINT_SYSTEM_PROMPT = """
You are the OSINT & Automation Agent for the Platr project.

MISSION:
Retrieve vehicle registration details for VIC (Victoria) plates from
open-source / publicly available endpoints, primarily:
1. VicRoads public rego check API (if available as REST endpoint)
2. Fallback: Selenium-driven headless browser scrape of the public portal
3. Final fallback: BeautifulSoup parse of cached/static pages

DATA TO EXTRACT:
- Registration status (current / expired / cancelled)
- Vehicle year, make, model
- Vehicle colour
- Expiry date

SAFETY & LEGAL:
- Only query publicly accessible data (no auth bypass)
- Rate limit: max 1 request / 3 seconds per plate
- Respect robots.txt
- Store raw response hash for audit trail

OUTPUT: async Python functions that backend_agent integrates as FastAPI
background tasks (via BackgroundTasks or Celery).
"""


def osint_agent_node(state: PlatrState) -> PlatrState:
    """OSINT agent processes scraping tasks."""
    print("[OSINTAgent] 🔍 OSINT görevleri işleniyor...")

    completed = []
    queue = state.get("task", {}).get("queue", [])

    for task in queue:
        if task["target"] == "osint" and task["id"] not in state.get("task", {}).get("completed", []):
            print(f"[OSINTAgent] → {task['id']}: {task['description'][:60]}...")
            completed.append(task["id"])

    state["task"]["completed"] = state["task"].get("completed", []) + completed
    state["current_agent"] = "done"

    print(f"[OSINTAgent] ✓ {len(completed)} görev tamamlandı: {completed}")
    return state
