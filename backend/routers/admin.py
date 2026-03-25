"""
Platr Backend — Admin Router.

Admin-only endpoints. Requires is_verified=True on the user account.
Set in DB: UPDATE users SET is_verified=true WHERE username='yourname';

Endpoints:
  POST /admin/run-moderation-agent       → Invoke the LangGraph Moderation Agent
  POST /admin/plates/{id}/approve-claim  → Approve a VicRoads ownership claim
  POST /admin/plates/{id}/reject-claim   → Reject a VicRoads ownership claim
  POST /admin/comments/{id}/delete       → Admin delete a comment
  POST /admin/users/{id}/ban             → Ban a user
"""

from __future__ import annotations

import logging
import uuid

from fastapi import APIRouter, HTTPException, status

from backend.dependencies import CurrentUser, DbDep
from backend.models.plate import Plate
from backend.models.comment import Comment
from backend.models.user import User

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/admin", tags=["admin"])


def _require_admin(user: CurrentUser) -> None:
    if not user.is_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required (is_verified must be True)",
        )


@router.post("/plates/{plate_id}/approve-claim", status_code=status.HTTP_200_OK)
async def approve_ownership_claim(
    plate_id: uuid.UUID,
    db: DbDep,
    current_user: CurrentUser,
) -> dict:
    """Approve the pending VicRoads ownership claim for a plate."""
    _require_admin(current_user)

    plate = await db.get(Plate, plate_id)
    if not plate:
        raise HTTPException(status_code=404, detail="Plate not found")
    if not plate.ownership_pending_user_id:
        raise HTTPException(status_code=400, detail="No pending claim on this plate")

    plate.owner_user_id = plate.ownership_pending_user_id
    plate.ownership_verified = True

    await db.commit()
    return {"detail": "Claim approved", "plate_id": str(plate_id), "owner_id": str(plate.owner_user_id)}


@router.post("/plates/{plate_id}/reject-claim", status_code=status.HTTP_200_OK)
async def reject_ownership_claim(
    plate_id: uuid.UUID,
    db: DbDep,
    current_user: CurrentUser,
) -> dict:
    """Reject the pending VicRoads ownership claim for a plate."""
    _require_admin(current_user)

    plate = await db.get(Plate, plate_id)
    if not plate:
        raise HTTPException(status_code=404, detail="Plate not found")

    plate.ownership_pending_user_id = None
    plate.vicroads_screenshot_path = None
    plate.vicroads_screenshot_at = None

    await db.commit()
    return {"detail": "Claim rejected", "plate_id": str(plate_id)}


@router.delete("/comments/{comment_id}", status_code=status.HTTP_200_OK)
async def admin_delete_comment(
    comment_id: uuid.UUID,
    db: DbDep,
    current_user: CurrentUser,
) -> dict:
    """Admin hard-hide (soft-delete) a comment."""
    _require_admin(current_user)

    from datetime import datetime, timezone
    comment = await db.get(Comment, comment_id)
    if not comment:
        raise HTTPException(status_code=404, detail="Comment not found")

    comment.is_hidden = True
    comment.deleted_at = datetime.now(timezone.utc)
    await db.commit()
    return {"detail": "Comment deleted by admin"}


@router.post("/users/{user_id}/ban", status_code=status.HTTP_200_OK)
async def ban_user(
    user_id: uuid.UUID,
    db: DbDep,
    current_user: CurrentUser,
) -> dict:
    """Ban a user (set is_active=False)."""
    _require_admin(current_user)

    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.is_active = False
    await db.commit()
    return {"detail": f"User @{user.username} banned", "user_id": str(user_id)}


@router.post("/run-moderation-agent", status_code=status.HTTP_200_OK)
async def run_moderation_agent_endpoint(
    current_user: CurrentUser,
) -> dict:
    """
    Invokes the LangGraph Moderation Agent.

    The agent:
      1. Fetches all visible (non-hidden, non-deleted) comments from the DB.
      2. Sends them to Claude (claude-haiku-4-5) with a hide_comment tool.
      3. Claude calls hide_comment() for each aggressive/inappropriate comment.
      4. Agent writes is_hidden=true to the DB for flagged comments.

    Returns a summary of what was reviewed and hidden.
    Requires: is_verified=True on your user account.
    """
    _require_admin(current_user)

    from agents.moderation_agent import run_moderation_agent

    logger.info(f"[Admin] Moderation agent triggered by user={current_user.username}")
    result = await run_moderation_agent()
    logger.info(f"[Admin] Agent done — {result['summary']}")

    return result
