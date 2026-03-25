"""
Platr Backend — Feed Router.
Unified activity feed: plate additions + comments, chronologically ordered.

GET /feed → paginated activity items
"""

from __future__ import annotations

import uuid
from datetime import datetime

from fastapi import APIRouter, Query
from pydantic import BaseModel
from sqlalchemy import select, union_all, literal, text
from sqlalchemy.ext.asyncio import AsyncSession

from backend.database import get_db
from backend.dependencies import DbDep
from backend.models.plate import Plate
from backend.models.comment import Comment
from backend.models.user import User

router = APIRouter(prefix="/feed", tags=["feed"])


class FeedItem(BaseModel):
    id: str
    type: str  # "plate_added" | "comment"
    created_at: datetime
    # Actor
    actor_user_id: str | None = None
    actor_username: str | None = None
    # Plate context
    plate_id: str
    plate_text: str
    state_code: str
    # Comment-specific
    comment_body: str | None = None


@router.get("", response_model=list[FeedItem])
async def get_feed(
    db: DbDep,
    limit: int = Query(30, ge=1, le=100),
    offset: int = Query(0, ge=0),
) -> list[FeedItem]:
    """
    Returns a unified, chronologically-ordered activity feed.
    Combines two event types:
      - plate_added: a user added a new plate
      - comment: a user commented on a plate
    """
    # -- Raw SQL via text() for a clean UNION ALL across two tables --
    sql = text("""
        (
            SELECT
                p.id::text            AS id,
                'plate_added'         AS type,
                p.created_at          AS created_at,
                p.submitted_by_user_id::text AS actor_user_id,
                u.username            AS actor_username,
                p.id::text            AS plate_id,
                p.plate_text          AS plate_text,
                p.state_code          AS state_code,
                NULL                  AS comment_body
            FROM plates p
            LEFT JOIN users u ON u.id = p.submitted_by_user_id
            WHERE p.is_hidden = false
        )
        UNION ALL
        (
            SELECT
                c.id::text            AS id,
                'comment'             AS type,
                c.created_at          AS created_at,
                c.author_user_id::text AS actor_user_id,
                u.username            AS actor_username,
                p.id::text            AS plate_id,
                p.plate_text          AS plate_text,
                p.state_code          AS state_code,
                c.body                AS comment_body
            FROM comments c
            JOIN plates p ON p.id = c.plate_id
            LEFT JOIN users u ON u.id = c.author_user_id
            WHERE c.deleted_at IS NULL
              AND c.is_hidden = false
              AND p.is_hidden = false
        )
        ORDER BY created_at DESC
        LIMIT :limit OFFSET :offset
    """)

    result = await db.execute(sql, {"limit": limit, "offset": offset})
    rows = result.mappings().all()

    return [
        FeedItem(
            id=row["id"],
            type=row["type"],
            created_at=row["created_at"],
            actor_user_id=row["actor_user_id"],
            actor_username=row["actor_username"],
            plate_id=row["plate_id"],
            plate_text=row["plate_text"],
            state_code=row["state_code"],
            comment_body=row["comment_body"],
        )
        for row in rows
    ]
