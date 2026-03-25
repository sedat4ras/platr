# Copyright (c) 2025 Sedat Aras — Platr. MIT License.
"""
Platr Backend — Plate ORM model.
[FastAPIDBAgent | BE-001]

KEY CONSTRAINT:
  UniqueConstraint("state_code", "plate_text") → HTTP 409 on duplicate,
  iOS client redirects to existing plate's detail view.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from sqlalchemy import (
    String,
    Boolean,
    DateTime,
    ForeignKey,
    UniqueConstraint,
    Enum as SAEnum,
    Integer,
    Text,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
import enum

from backend.database import Base


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


class PlateStyle(str, enum.Enum):
    """VIC plate visual template identifiers."""
    VIC_STANDARD = "VIC_STANDARD"   # White bg, blue border — "The Education State"
    VIC_BLACK    = "VIC_BLACK"      # Heritage matte black, chrome border
    VIC_CUSTOM   = "VIC_CUSTOM"     # Fully configurable: bg/text/border/badge/separator


class RegoStatus(str, enum.Enum):
    CURRENT   = "CURRENT"
    EXPIRED   = "EXPIRED"
    CANCELLED = "CANCELLED"
    UNKNOWN   = "UNKNOWN"
    PENDING   = "PENDING"   # Initial state before OSINT check completes


class Plate(Base):
    __tablename__ = "plates"

    __table_args__ = (
        # Core uniqueness: one record per [state + plate text] combination
        UniqueConstraint("state_code", "plate_text", name="uq_plates_state_text"),
    )

    # ── Identity ─────────────────────────────────────────────────────────────
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )

    # ── Plate data ───────────────────────────────────────────────────────────
    state_code: Mapped[str] = mapped_column(String(10), nullable=False, index=True)
    plate_text: Mapped[str] = mapped_column(String(10), nullable=False, index=True)
    plate_style: Mapped[PlateStyle] = mapped_column(
        SAEnum(PlateStyle, name="plate_style_enum"),
        default=PlateStyle.VIC_STANDARD,
        nullable=False,
    )

    # Custom plate configuration — JSON string (populated for VIC_CUSTOM plates)
    custom_config: Mapped[str | None] = mapped_column(Text, nullable=True)

    # ── Vehicle details (populated by OSINT / RegoCheck) ─────────────────────
    vehicle_year: Mapped[int | None] = mapped_column(Integer)
    vehicle_make: Mapped[str | None] = mapped_column(String(100))
    vehicle_model: Mapped[str | None] = mapped_column(String(100))
    vehicle_color: Mapped[str | None] = mapped_column(String(50))
    rego_status: Mapped[RegoStatus] = mapped_column(
        SAEnum(RegoStatus, name="rego_status_enum"),
        default=RegoStatus.PENDING,
        nullable=False,
    )
    rego_expiry_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    rego_checked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    # ── Display preferences ────────────────────────────────────────────────
    has_space_separator: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    custom_bg_color: Mapped[str | None] = mapped_column(String(7))  # hex e.g. "#FF0000"

    # ── Ownership & community ────────────────────────────────────────────────
    owner_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), index=True
    )
    submitted_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )

    # Owner can lock comments on their own plate (App Store UGC compliance)
    is_comments_open: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # VIN verification — SHA-256 hash of last 6 chars of VIN (legacy, kept for compat)
    vin_last6_hash: Mapped[str | None] = mapped_column(String(64))

    # ── Photo-based ownership verification ─────────────────────────────────
    ownership_photo_day1_path: Mapped[str | None] = mapped_column(String(500))
    ownership_photo_day1_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    ownership_photo_day2_path: Mapped[str | None] = mapped_column(String(500))
    ownership_photo_day2_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    ownership_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    ownership_pending_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )

    # ── Visibility controls (owner privileges) ─────────────────────────────
    is_hidden: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_blocked_readd: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # ── Plate photo (owner can upload real plate photo for display) ──────────
    plate_photo_path: Mapped[str | None] = mapped_column(String(500))

    # ── VicRoads screenshot for ownership verification ───────────────────────
    vicroads_screenshot_path: Mapped[str | None] = mapped_column(String(500))
    vicroads_screenshot_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    # Star count (incremented/decremented by PlateStarring) + view count
    star_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    view_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    # ── Timestamps ───────────────────────────────────────────────────────────
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False
    )

    # ── Relationships ────────────────────────────────────────────────────────
    owner: Mapped["User"] = relationship(  # noqa: F821
        "User", back_populates="plates", foreign_keys=[owner_user_id]
    )
    submitter: Mapped["User | None"] = relationship(  # noqa: F821
        "User", foreign_keys=[submitted_by_user_id], viewonly=True
    )
    comments: Mapped[list["Comment"]] = relationship(  # noqa: F821
        "Comment", back_populates="plate", cascade="all, delete-orphan"
    )
    starring: Mapped[list["PlateStarring"]] = relationship(  # noqa: F821
        "PlateStarring", back_populates="plate", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<Plate {self.state_code}·{self.plate_text} [{self.plate_style}]>"
