"""
Platr Backend — PlateStarring ORM model.

One row per (user, plate) pair. Unique constraint prevents double-starring.
star_count on Plate is kept in sync (increment on insert, decrement on delete).
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.database import Base


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


class PlateStarring(Base):
    __tablename__ = "plate_starring"

    __table_args__ = (
        UniqueConstraint("plate_id", "user_id", name="uq_starring_plate_user"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    plate_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("plates.id", ondelete="CASCADE"), nullable=False, index=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_utcnow, nullable=False
    )

    plate: Mapped["Plate"] = relationship("Plate", back_populates="starring")  # noqa: F821
    user: Mapped["User"] = relationship("User")  # noqa: F821
