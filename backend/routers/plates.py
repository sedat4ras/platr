# Copyright (c) 2025 Sedat Aras — Platr. MIT License.
"""
Platr Backend — Plates Router.
[FastAPIDBAgent | BE-002]

IMPORTANT: In FastAPI, literal path segments (/search, /submitted-by-me) MUST
be defined BEFORE path-parameter routes (/{plate_id}) to avoid being swallowed
by the UUID path converter.

POST /plates              → Create plate; HTTP 409 + existing_plate_id on duplicate
GET  /plates              → Paginated list with optional state_code filter
GET  /plates/search       → Prefix search on plate_text
GET  /plates/submitted-by-me → Current user's submitted plates (auth required)
GET  /plates/{id}         → Plate detail (increments view_count)
PATCH /plates/{id}        → Update style/icons/comments_open (owner only)
POST  /plates/{id}/spot   → Increment spot_count (authenticated)
POST  /plates/{id}/recheck → Re-trigger VicRoads rego check
"""

from __future__ import annotations

import json as _json
import uuid
from typing import Annotated

import os
import aiofiles

from fastapi import APIRouter, BackgroundTasks, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy import select, or_
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from backend.database import get_db
from backend.dependencies import CurrentUser, CurrentUserOptional, DbDep
from backend.models.plate import Plate, RegoStatus
from backend.schemas.plate import (
    DuplicatePlateResponse,
    PlateCreate,
    PlateRead,
    PlateUpdate,
)
from backend.services.rego_check import enqueue_rego_check

router = APIRouter(prefix="/plates", tags=["plates"])


# ── Helpers ──────────────────────────────────────────────────────────────────

async def _get_plate_or_404(plate_id: uuid.UUID, db: AsyncSession) -> Plate:
    plate = await db.get(Plate, plate_id)
    if not plate:
        raise HTTPException(status_code=404, detail="Plate not found")
    return plate


# ── Literal-path endpoints (MUST come before /{plate_id}) ────────────────────

@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=PlateRead,
    responses={
        409: {"model": DuplicatePlateResponse, "description": "Plate already exists"},
    },
)
async def create_plate(
    payload: PlateCreate,
    background_tasks: BackgroundTasks,
    db: DbDep,
    current_user: CurrentUser,
) -> PlateRead:
    """
    Create a new plate entry.

    On duplicate (state_code + plate_text already exists) returns HTTP 409
    with the existing plate's UUID so the iOS client can navigate to it.
    """
    # Check if a blocked plate exists with the same state + text
    blocked_plate = await db.scalar(
        select(Plate).where(
            Plate.state_code == payload.state_code.upper(),
            Plate.plate_text == payload.plate_text.upper(),
            Plate.is_blocked_readd == True,  # noqa: E712
        )
    )
    if blocked_plate:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This plate has been blocked from being re-added by its owner.",
        )

    plate = Plate(
        state_code="VIC",
        plate_text=payload.plate_text,
        plate_style=payload.plate_style,
        has_space_separator=payload.has_space_separator,
        custom_bg_color=payload.custom_bg_color,
        custom_config=_json.dumps(payload.custom_config) if payload.custom_config else None,
        submitted_by_user_id=current_user.id,
    )

    db.add(plate)

    try:
        await db.flush()
    except IntegrityError:
        await db.rollback()

        # Fetch the existing plate so we can return its ID
        existing = await db.scalar(
            select(Plate).where(
                Plate.state_code == payload.state_code,
                Plate.plate_text == payload.plate_text,
            )
        )

        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=DuplicatePlateResponse(
                existing_plate_id=existing.id,
                state_code=existing.state_code,
                plate_text=existing.plate_text,
            ).model_dump(mode="json"),
        )

    await db.commit()
    await db.refresh(plate)

    # Fire async OSINT rego check — does not block the response
    background_tasks.add_task(
        enqueue_rego_check,
        plate_id=plate.id,
        state_code=plate.state_code,
        plate_text=plate.plate_text,
    )

    return PlateRead.from_orm_with_vehicle(plate)


@router.get("", response_model=list[PlateRead])
async def list_plates(
    db: DbDep,
    state_code: str | None = Query(None, description="Filter by state, e.g. VIC"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
) -> list[PlateRead]:
    stmt = (
        select(Plate)
        .options(selectinload(Plate.submitter))
        .where(Plate.is_hidden == False)  # noqa: E712
        .offset(offset)
        .limit(limit)
        .order_by(Plate.created_at.desc())
    )
    if state_code:
        stmt = stmt.where(Plate.state_code == state_code.upper())

    result = await db.scalars(stmt)
    plates = result.all()
    return [PlateRead.from_orm_with_vehicle(p) for p in plates]


@router.get("/search", response_model=list[PlateRead])
async def search_plates(
    db: DbDep,
    q: str = Query(..., min_length=1, description="Plate text to search"),
    state_code: str | None = Query(None),
    limit: int = Query(20, ge=1, le=100),
) -> list[PlateRead]:
    """Full-text prefix search on plate_text."""
    # Normalize: strip non-alphanumeric for matching
    normalized = "".join(c for c in q.upper() if c.isalnum())
    stmt = (
        select(Plate)
        .options(selectinload(Plate.submitter))
        .where(
            Plate.is_hidden == False,  # noqa: E712
            or_(
                Plate.plate_text.ilike(f"{normalized}%"),
                Plate.plate_text.ilike(f"%{normalized}%"),
            ),
        )
        .order_by(Plate.star_count.desc())
        .limit(limit)
    )
    if state_code:
        stmt = stmt.where(Plate.state_code == state_code.upper())
    result = await db.scalars(stmt)
    return [PlateRead.from_orm_with_vehicle(p) for p in result.all()]


@router.get("/submitted-by-me", response_model=list[PlateRead])
async def get_my_submitted_plates(
    db: DbDep,
    current_user: CurrentUser,
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
) -> list[PlateRead]:
    """Return all plates submitted by the currently authenticated user."""
    stmt = (
        select(Plate)
        .options(selectinload(Plate.submitter))
        .where(Plate.submitted_by_user_id == current_user.id)
        .order_by(Plate.created_at.desc())
        .offset(offset)
        .limit(limit)
    )
    result = await db.scalars(stmt)
    return [PlateRead.from_orm_with_vehicle(p) for p in result.all()]


@router.get("/owned-by-me", response_model=list[PlateRead])
async def get_my_owned_plates(
    db: DbDep,
    current_user: CurrentUser,
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
) -> list[PlateRead]:
    """Return all plates owned (claimed) by the currently authenticated user."""
    stmt = (
        select(Plate)
        .options(selectinload(Plate.submitter))
        .where(Plate.owner_user_id == current_user.id)
        .order_by(Plate.created_at.desc())
        .offset(offset)
        .limit(limit)
    )
    result = await db.scalars(stmt)
    return [PlateRead.from_orm_with_vehicle(p) for p in result.all()]


# ── Path-parameter endpoints (/{plate_id}) ────────────────────────────────────

@router.get("/{plate_id}", response_model=PlateRead)
async def get_plate(
    plate_id: uuid.UUID,
    db: DbDep,
    current_user: CurrentUserOptional = None,
) -> PlateRead:
    plate = await db.scalar(
        select(Plate)
        .where(Plate.id == plate_id)
        .options(selectinload(Plate.submitter))
    )
    if not plate:
        raise HTTPException(status_code=404, detail="Plate not found")

    # Hidden plates are only visible to their owner
    if plate.is_hidden:
        if current_user is None or plate.owner_user_id != current_user.id:
            raise HTTPException(status_code=404, detail="Plate not found")

    plate.view_count += 1
    await db.commit()
    return PlateRead.from_orm_with_vehicle(plate)


@router.patch("/{plate_id}", response_model=PlateRead)
async def update_plate(
    plate_id: uuid.UUID,
    payload: PlateUpdate,
    db: DbDep,
    current_user: CurrentUser,
) -> PlateRead:
    plate = await _get_plate_or_404(plate_id, db)

    if plate.owner_user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the plate owner can update it")

    update_data = payload.model_dump(exclude_none=True)
    for field, value in update_data.items():
        setattr(plate, field, value)

    await db.commit()
    await db.refresh(plate)
    return PlateRead.from_orm_with_vehicle(plate)



@router.post("/{plate_id}/photo", response_model=PlateRead)
async def upload_plate_photo(
    plate_id: uuid.UUID,
    db: DbDep,
    current_user: CurrentUser,
    photo: UploadFile = File(...),
) -> PlateRead:
    """Upload a real photo for a plate (replaces the rendered visual)."""
    plate = await _get_plate_or_404(plate_id, db)

    upload_dir = "uploads/plate_photos"
    os.makedirs(upload_dir, exist_ok=True)
    filename = f"{plate_id}.jpg"
    filepath = os.path.join(upload_dir, filename)

    async with aiofiles.open(filepath, "wb") as f:
        content = await photo.read()
        await f.write(content)

    plate.plate_photo_path = filepath
    await db.commit()
    await db.refresh(plate)
    return PlateRead.from_orm_with_vehicle(plate)


@router.post("/{plate_id}/recheck", status_code=status.HTTP_202_ACCEPTED)
async def recheck_plate_rego(
    plate_id: uuid.UUID,
    background_tasks: BackgroundTasks,
    db: DbDep,
    current_user: CurrentUser,
) -> dict:
    """
    Re-trigger a VicRoads rego check for an existing plate.
    Useful when rego status is UNKNOWN or stale.
    """
    plate = await _get_plate_or_404(plate_id, db)

    # Mark as PENDING so the iOS client can show "Checking..." immediately
    plate.rego_status = RegoStatus.PENDING
    await db.commit()

    background_tasks.add_task(
        enqueue_rego_check,
        plate_id=plate.id,
        state_code=plate.state_code,
        plate_text=plate.plate_text,
    )

    return {"detail": "Rego re-check queued", "plate_id": str(plate.id)}
