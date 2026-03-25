# Copyright (c) 2025 Sedat Aras — Platr. MIT License.
"""
Platr Backend — Plate Starring Router.

POST   /plates/{plate_id}/star   → Star a plate (one per user)
DELETE /plates/{plate_id}/star   → Unstar a plate
GET    /plates/{plate_id}/star   → Check if current user has starred this plate
"""

from __future__ import annotations

import uuid

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from backend.dependencies import CurrentUser, DbDep
from backend.models.plate import Plate
from backend.models.star import PlateStarring

router = APIRouter(prefix="/plates", tags=["stars"])


@router.post("/{plate_id}/star", status_code=status.HTTP_200_OK)
async def star_plate(plate_id: uuid.UUID, db: DbDep, current_user: CurrentUser) -> dict:
    """Star a plate. Returns current star_count. Idempotent — no error if already starred."""
    plate = await db.get(Plate, plate_id)
    if not plate:
        raise HTTPException(status_code=404, detail="Plate not found")

    existing = await db.scalar(
        select(PlateStarring).where(
            PlateStarring.plate_id == plate_id,
            PlateStarring.user_id == current_user.id,
        )
    )
    if existing:
        return {"star_count": plate.star_count, "starred": True}

    starring = PlateStarring(plate_id=plate_id, user_id=current_user.id)
    db.add(starring)

    try:
        await db.flush()
    except IntegrityError:
        await db.rollback()
        return {"star_count": plate.star_count, "starred": True}

    plate.star_count += 1
    await db.commit()
    return {"star_count": plate.star_count, "starred": True}


@router.delete("/{plate_id}/star", status_code=status.HTTP_200_OK)
async def unstar_plate(plate_id: uuid.UUID, db: DbDep, current_user: CurrentUser) -> dict:
    """Remove star from a plate. Idempotent — no error if not starred."""
    plate = await db.get(Plate, plate_id)
    if not plate:
        raise HTTPException(status_code=404, detail="Plate not found")

    starring = await db.scalar(
        select(PlateStarring).where(
            PlateStarring.plate_id == plate_id,
            PlateStarring.user_id == current_user.id,
        )
    )
    if not starring:
        return {"star_count": plate.star_count, "starred": False}

    await db.delete(starring)
    plate.star_count = max(0, plate.star_count - 1)
    await db.commit()
    return {"star_count": plate.star_count, "starred": False}


@router.get("/{plate_id}/star", status_code=status.HTTP_200_OK)
async def get_star_status(plate_id: uuid.UUID, db: DbDep, current_user: CurrentUser) -> dict:
    """Check if the current user has starred this plate."""
    plate = await db.get(Plate, plate_id)
    if not plate:
        raise HTTPException(status_code=404, detail="Plate not found")

    starring = await db.scalar(
        select(PlateStarring).where(
            PlateStarring.plate_id == plate_id,
            PlateStarring.user_id == current_user.id,
        )
    )
    return {"star_count": plate.star_count, "starred": starring is not None}
