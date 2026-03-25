"""
Platr Multi-Agent — FastAPI & DB Agent (Backend Developer)
Responsible for: Python, FastAPI, PostgreSQL, SQLAlchemy, REST endpoints,
Unique Constraint logic, duplicate-redirect responses.
"""

from agents.state import PlatrState

BACKEND_SYSTEM_PROMPT = """
You are the FastAPI & DB Agent for the Platr project.

TECH STACK:
- Python 3.12+, FastAPI, SQLAlchemy 2.x (async), Alembic, PostgreSQL 16
- Pydantic v2 for request/response schemas
- asyncpg driver for PostgreSQL

KEY BUSINESS RULES:
1. UNIQUE CONSTRAINT: (state_code, plate_text) must be unique in plates table.
   On duplicate → HTTP 409 with existing plate's UUID in response body (iOS
   redirects user to existing plate view).
2. RegoCheck: After plate creation, fire background task to call osint service
   and update (year, make, model, color, rego_status) asynchronously.
3. Comments: soft-delete only (deleted_at timestamp). Hard delete forbidden.
4. Ownership: plate.owner_user_id can toggle is_comments_open (bool).
5. All UGC (comments) have is_reported + blocked_by fields.

OUTPUT: Complete, production-ready Python files with type hints.
"""


def backend_agent_node(state: PlatrState) -> PlatrState:
    """Backend agent processes its queue items."""
    print("[FastAPIDBAgent] ⚙️  Backend görevleri işleniyor...")

    completed = []
    queue = state.get("task", {}).get("queue", [])

    for task in queue:
        if task["target"] == "backend" and task["id"] not in state.get("task", {}).get("completed", []):
            print(f"[FastAPIDBAgent] → {task['id']}: {task['description'][:60]}...")
            completed.append(task["id"])

    state["task"]["completed"] = state["task"].get("completed", []) + completed
    state["current_agent"] = "ios"

    print(f"[FastAPIDBAgent] ✓ {len(completed)} görev tamamlandı: {completed}")
    return state
