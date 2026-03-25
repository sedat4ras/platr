"""
Platr Backend — Comments Router.
[FastAPIDBAgent | BE-002]

App Store Guideline 1.2 (UGC) compliance:
  POST /comments/{id}/report  → Report a comment
  POST /comments/{id}/block   → Block the comment's author

Soft-delete only — no hard deletes ever.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone
from typing import Annotated

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from backend.database import get_db
from backend.dependencies import CurrentUser, DbDep
from backend.models.comment import Comment
from backend.models.plate import Plate
from backend.schemas.comment import (
    BlockRequest,
    CommentCreate,
    CommentRead,
    ReportRequest,
)

router = APIRouter(prefix="/plates/{plate_id}/comments", tags=["comments"])
UGC_router = APIRouter(prefix="/comments", tags=["comments-ugc"])


async def _get_comment_or_404(comment_id: uuid.UUID, db: AsyncSession) -> Comment:
    c = await db.get(Comment, comment_id)
    if not c or c.is_deleted:
        raise HTTPException(status_code=404, detail="Comment not found")
    return c


@router.get("", response_model=list[CommentRead])
async def list_comments(
    plate_id: uuid.UUID,
    db: DbDep,
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
) -> list[CommentRead]:
    plate = await db.get(Plate, plate_id)
    if not plate:
        raise HTTPException(status_code=404, detail="Plate not found")

    stmt = (
        select(Comment)
        .where(
            Comment.plate_id == plate_id,
            Comment.deleted_at.is_(None),
            Comment.is_hidden.is_(False),
        )
        .options(selectinload(Comment.author))
        .order_by(Comment.created_at.desc())
        .offset(offset)
        .limit(limit)
    )
    result = await db.scalars(stmt)
    return [CommentRead.from_orm(c) for c in result.all()]


@router.post("", status_code=status.HTTP_201_CREATED, response_model=CommentRead)
async def create_comment(
    plate_id: uuid.UUID,
    payload: CommentCreate,
    background_tasks: BackgroundTasks,
    db: DbDep,
    current_user: CurrentUser,
) -> CommentRead:
    plate = await db.get(Plate, plate_id)
    if not plate:
        raise HTTPException(status_code=404, detail="Plate not found")
    if not plate.is_comments_open:
        raise HTTPException(status_code=403, detail="Comments are closed for this plate")

    # ── Layer 1 Moderation: keyword scan (sync, free, zero latency) ───────────
    from backend.services.moderation import moderate_comment

    mod = moderate_comment(payload.body)

    comment = Comment(
        plate_id=plate_id,
        author_user_id=current_user.id,
        body=payload.body,
        is_hidden=not mod.is_appropriate,
    )
    db.add(comment)
    await db.commit()

    # Reload with author relationship so author_username is populated
    from sqlalchemy import select as sa_select
    comment = await db.scalar(
        sa_select(Comment)
        .where(Comment.id == comment.id)
        .options(selectinload(Comment.author))
    )

    # Notify admin if keyword filter was triggered
    if not mod.is_appropriate:
        from backend.services.email import send_admin_moderation_alert
        background_tasks.add_task(
            send_admin_moderation_alert,
            trigger="Keyword Filter",
            comment_id=str(comment.id),
            plate_text=str(plate_id),
            author_username=current_user.username,
            comment_body=payload.body,
            reason=mod.reason,
        )

    return CommentRead.from_orm(
        comment,
        was_moderated=not mod.is_appropriate,
        moderation_warning=mod.warning_message,
    )


@UGC_router.post("/{comment_id}/report", status_code=status.HTTP_200_OK)
async def report_comment(
    comment_id: uuid.UUID,
    payload: ReportRequest,
    background_tasks: BackgroundTasks,
    db: DbDep,
    current_user: CurrentUser,
) -> dict:
    """
    Report a comment (App Store UGC Guideline 1.2).
    Adds the reporting user's ID to comment.reported_by array.
    Auto-hides after 5 unique reports.
    """
    comment = await _get_comment_or_404(comment_id, db)

    reporting_user_id = str(current_user.id)
    if reporting_user_id not in (comment.reported_by or []):
        comment.reported_by = list(comment.reported_by or []) + [reporting_user_id]

    AUTO_HIDE_THRESHOLD = 5
    if len(comment.reported_by) >= AUTO_HIDE_THRESHOLD:
        comment.is_hidden = True

    await db.commit()

    # Notify admin of report
    from backend.services.email import send_admin_moderation_alert
    author_username = getattr(getattr(comment, "author", None), "username", "unknown")
    background_tasks.add_task(
        send_admin_moderation_alert,
        trigger="User Report",
        comment_id=str(comment_id),
        plate_text=str(comment.plate_id),
        author_username=author_username,
        comment_body=comment.body,
        reason=getattr(payload, "reason", "No reason given"),
    )

    return {"detail": "Reported successfully", "report_count": len(comment.reported_by)}


@UGC_router.post("/{comment_id}/block", status_code=status.HTTP_200_OK)
async def block_comment_author(
    comment_id: uuid.UUID,
    _payload: BlockRequest,
    db: DbDep,
    current_user: CurrentUser,
) -> dict:
    """
    Block the author of a comment (App Store UGC Guideline 1.2).
    Adds the blocking user's ID to comment.blocked_by.
    iOS client then filters out all content from that author locally.
    """
    comment = await _get_comment_or_404(comment_id, db)

    blocking_user_id = str(current_user.id)
    if blocking_user_id not in (comment.blocked_by or []):
        comment.blocked_by = list(comment.blocked_by or []) + [blocking_user_id]

    await db.commit()
    return {"detail": "Author blocked successfully"}


@UGC_router.delete("/{comment_id}", status_code=status.HTTP_200_OK)
async def delete_comment(
    comment_id: uuid.UUID,
    db: DbDep,
    current_user: CurrentUser,
) -> dict:
    """Soft-delete a comment. Only the author or the plate's owner can delete."""
    comment = await _get_comment_or_404(comment_id, db)

    plate = await db.get(Plate, comment.plate_id)
    is_author = comment.author_user_id == current_user.id
    is_plate_owner = plate and plate.owner_user_id == current_user.id

    if not (is_author or is_plate_owner):
        raise HTTPException(status_code=403, detail="Not authorised to delete this comment")

    comment.deleted_at = datetime.now(timezone.utc)
    await db.commit()
    return {"detail": "Comment deleted"}
