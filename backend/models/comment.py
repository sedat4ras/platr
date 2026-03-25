"""
Platr Backend — Comment ORM model.
[FastAPIDBAgent | BE-001]

UGC COMPLIANCE (App Store Guideline 1.2):
- Every comment carries is_reported / blocked_by fields.
- Soft-delete only: deleted_at is set; row is never hard-deleted.
- Moderation: is_hidden flag set by automated or manual review.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from sqlalchemy import String, Boolean, DateTime, ForeignKey, Text, ARRAY
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.database import Base


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


class Comment(Base):
    __tablename__ = "comments"

    # ── Identity ─────────────────────────────────────────────────────────────
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )

    # ── Content ──────────────────────────────────────────────────────────────
    body: Mapped[str] = mapped_column(Text, nullable=False)

    # ── Foreign keys ─────────────────────────────────────────────────────────
    plate_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("plates.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    author_user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # ── UGC compliance fields (App Store Rule 1.2) ───────────────────────────
    # Users who reported this comment (list of user UUIDs as strings)
    reported_by: Mapped[list[str]] = mapped_column(
        ARRAY(String), default=list, nullable=False, server_default="{}"
    )
    # Users who blocked the author (list of user UUIDs)
    blocked_by: Mapped[list[str]] = mapped_column(
        ARRAY(String), default=list, nullable=False, server_default="{}"
    )
    is_hidden: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # ── Soft delete ──────────────────────────────────────────────────────────
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    # ── Timestamps ───────────────────────────────────────────────────────────
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False
    )

    # ── Relationships ────────────────────────────────────────────────────────
    plate: Mapped["Plate"] = relationship("Plate", back_populates="comments")  # noqa: F821
    author: Mapped["User"] = relationship("User", back_populates="comments")   # noqa: F821

    @property
    def is_deleted(self) -> bool:
        return self.deleted_at is not None

    def __repr__(self) -> str:
        return f"<Comment id={self.id} plate_id={self.plate_id} deleted={self.is_deleted}>"
