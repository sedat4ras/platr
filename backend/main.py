"""
Platr Backend — FastAPI application entry point.
[FastAPIDBAgent | BE-002]

Run with: uvicorn backend.main:app --reload --port 8000
"""

from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.config import settings
from backend.database import init_db
from backend.routers.admin import router as admin_router
from backend.routers.auth import router as auth_router
from backend.routers.plates import router as plates_router
from backend.routers.comments import router as comments_router, UGC_router
from backend.routers.users import router as users_router
from backend.routers.ownership import router as ownership_router
from backend.routers.feed import router as feed_router
from backend.routers.stars import router as stars_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup / shutdown lifecycle."""
    # Dev: auto-create tables. In production use Alembic migrations.
    if settings.debug:
        await init_db()
    yield


app = FastAPI(
    title=settings.app_name,
    version=settings.api_version,
    description=(
        "Platr API — Carspotting & community platform for vehicle plates. "
        "VIC-first, powered by FastAPI + PostgreSQL."
    ),
    lifespan=lifespan,
)

# ── CORS ─────────────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ───────────────────────────────────────────────────────────────────
API_PREFIX = f"/api/{settings.api_version}"

app.include_router(admin_router,     prefix=API_PREFIX)
app.include_router(auth_router,      prefix=API_PREFIX)
app.include_router(users_router,     prefix=API_PREFIX)
app.include_router(plates_router,    prefix=API_PREFIX)
app.include_router(ownership_router, prefix=API_PREFIX)
app.include_router(comments_router,  prefix=API_PREFIX)
app.include_router(UGC_router,       prefix=API_PREFIX)
app.include_router(feed_router,      prefix=API_PREFIX)
app.include_router(stars_router,     prefix=API_PREFIX)


# ── Static files (avatar uploads) ─────────────────────────────────────────────
import os
from fastapi.staticfiles import StaticFiles

_uploads = os.path.join(os.path.dirname(__file__), "..", "uploads")
os.makedirs(_uploads, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=_uploads), name="uploads")

# ── Health check ──────────────────────────────────────────────────────────────
@app.get("/health", tags=["health"])
async def health_check() -> dict:
    return {"status": "ok", "app": settings.app_name, "version": settings.api_version}
