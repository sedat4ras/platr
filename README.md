# Platr

**Carspotting & community platform for vehicle plates.**
Victoria (VIC) first. iOS Native (SwiftUI) + Python FastAPI backend.

---

## Project Structure

```
Platr/
├── agents/          # LangChain/LangGraph multi-agent orchestration
├── backend/         # Python FastAPI + PostgreSQL
└── ios/Platr/       # SwiftUI iOS 17+ app
```

---

## Backend Setup

```bash
cd backend

# 1. Create virtual environment
python3 -m venv .venv && source .venv/bin/activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Configure environment
cp .env.example .env
# Edit .env with your PostgreSQL credentials

# 4. Start PostgreSQL (Docker)
docker run -d \
  --name platr-db \
  -e POSTGRES_USER=platr \
  -e POSTGRES_PASSWORD=platr \
  -e POSTGRES_DB=platr \
  -p 5432:5432 \
  postgres:16

# 5. Run database migrations
alembic upgrade head

# 6. Start API server
uvicorn backend.main:app --reload --port 8000
```

API docs: http://localhost:8000/docs

---

## iOS Setup

1. Open `ios/` in Xcode 15+
2. Set deployment target to iOS 17.0
3. Add all Swift files to the `Platr` target
4. Update `APIService.baseURL` to point to your backend
5. Build & run on Simulator or device

> **Note:** All SourceKit cross-file errors shown in the editor resolve automatically when Xcode builds the module target.

---

## Multi-Agent System

```bash
# From project root (with venv active)
python -m agents.orchestrator
```

---

## Key Design Decisions

| Concern | Decision |
|---------|----------|
| Plate uniqueness | `UNIQUE(state_code, plate_text)` → HTTP 409 + redirect |
| Photo upload | **Prohibited** — ZStack vector render only |
| UGC compliance | Every comment has Report + Block (App Store Rule 1.2) |
| RegoCheck | Async background task, VicRoads HTML scrape + OSINT |
| Comments moderation | Soft-delete only, auto-hide at 5 reports |
| Ownership | Plate owner can toggle `is_comments_open` |

---

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/plates` | Create plate (409 on duplicate) |
| `GET`  | `/api/v1/plates` | List plates (filter by state) |
| `GET`  | `/api/v1/plates/{id}` | Plate detail |
| `PATCH`| `/api/v1/plates/{id}` | Update style / toggle comments |
| `POST` | `/api/v1/plates/{id}/spot` | Spot a plate |
| `GET`  | `/api/v1/plates/{id}/comments` | List comments |
| `POST` | `/api/v1/plates/{id}/comments` | Post comment |
| `POST` | `/api/v1/comments/{id}/report` | Report (UGC Rule 1.2) |
| `POST` | `/api/v1/comments/{id}/block` | Block author (UGC Rule 1.2) |
| `DELETE`| `/api/v1/comments/{id}` | Soft-delete comment |
