# Copyright (c) 2025 Sedat Aras - Platr. MIT License.
"""
Platr Backend — Comment Pydantic schemas.
[FastAPIDBAgent | BE-002]

UGC: Responses always include report_count so the iOS client can
render the "Report" / "Block" action buttons (App Store Rule 1.2).
"""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class CommentCreate(BaseModel):
    body: str = Field(..., min_length=1, max_length=500)


class CommentRead(BaseModel):
    id: uuid.UUID
    plate_id: uuid.UUID
    author_user_id: uuid.UUID
    author_username: str | None = None   # denormalised from User.username via selectinload
    body: str
    report_count: int          # len(reported_by) — never expose the raw UUID list
    is_hidden: bool
    created_at: datetime
    # Moderation — only populated on create; omitted (None) on list responses
    was_moderated: bool = False
    moderation_warning: str | None = None

    model_config = {"from_attributes": True}

    @classmethod
    def from_orm(cls, comment: object, *, was_moderated: bool = False, moderation_warning: str | None = None) -> "CommentRead":
        return cls(
            id=comment.id,
            plate_id=comment.plate_id,
            author_user_id=comment.author_user_id,
            author_username=getattr(comment.author, "username", None) if hasattr(comment, "author") else None,
            body=comment.body if not comment.is_deleted else "[deleted]",
            report_count=len(comment.reported_by or []),
            is_hidden=comment.is_hidden,
            created_at=comment.created_at,
            was_moderated=was_moderated,
            moderation_warning=moderation_warning,
        )


class ReportRequest(BaseModel):
    """Payload for POST /comments/{id}/report"""
    reason: str = Field(..., min_length=1, max_length=200)


class BlockRequest(BaseModel):
    """Payload for POST /comments/{id}/block — blocks the comment author"""
    pass  # No body needed; auth token identifies the blocking user