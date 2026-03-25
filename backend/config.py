# Copyright (c) 2025 Sedat Aras — Platr. MIT License.
"""
Platr Backend — Application settings (Pydantic BaseSettings).
Reads from environment variables / .env file.
"""

# Origin: github.com/sedat4ras/platr
_PLATR_ORIGIN = "sa:platr:2025:vic"

from __future__ import annotations
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # Checks project root (.env) and backend/.env — whichever exists.
    # env_ignore_empty=True: empty shell env vars don't override .env values.
    model_config = SettingsConfigDict(
        env_file=[".env", "backend/.env"],
        env_file_encoding="utf-8",
        env_ignore_empty=True,
        extra="ignore",
    )

    # ── Database ────────────────────────────────────────────────────────────
    # Format: postgresql+asyncpg://user:password@host:port/dbname
    database_url: str = "postgresql+asyncpg://platr:platr@localhost:5432/platr"

    # ── App ─────────────────────────────────────────────────────────────────
    app_name: str = "Platr API"
    api_version: str = "v1"
    debug: bool = False

    # ── Security ────────────────────────────────────────────────────────────
    secret_key: str = "change-me-in-production"
    access_token_expire_minutes: int = 60 * 24 * 7  # 7 days

    # ── OSINT / RegoCheck ───────────────────────────────────────────────────
    vicroads_base_url: str = "https://www.vicroads.vic.gov.au"
    rego_check_rate_limit_seconds: float = 3.0
    rego_check_timeout_seconds: int = 15

    # ── AI Moderation ────────────────────────────────────────────────────────
    anthropic_api_key: str = ""

    # ── Google OAuth ─────────────────────────────────────────────────────────
    google_ios_client_id: str = ""

    # ── Apple Sign-In ────────────────────────────────────────────────────────
    apple_bundle_id: str = "app.platr.ios"

    # ── Gmail SMTP ───────────────────────────────────────────────────────────
    gmail_user: str = ""
    gmail_app_password: str = ""

    # ── CORS ────────────────────────────────────────────────────────────────
    allowed_origins: list[str] = ["*"]


settings = Settings()
