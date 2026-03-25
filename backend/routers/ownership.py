"""
Platr Backend — Plate Ownership Router (Photo-Based Verification).
[FastAPIDBAgent]

Photo-based ownership flow:
  1. User taps "Claim This Plate" in iOS app
  2. POST /plates/{id}/claim/photo  (multipart photo) → saves day-1 photo, records pending user
  3. 20-48 hours later, user submits day-2 photo → ownership verified
  4. Owner can then:
     - PATCH /plates/{id}/visibility → hide plate or block re-add
     - PATCH /plates/{id}/comments/toggle → toggle is_comments_open
     - DELETE /plates/{id}/claim → relinquish ownership + clear all photos

Security: two-day consecutive photo verification prevents casual false claims.
Photos are stored on disk under uploads/ownership/{plate_id}/.
"""

from __future__ import annotations

import os
import uuid
from datetime import datetime, timezone, timedelta

from fastapi import APIRouter, BackgroundTasks, HTTPException, UploadFile, File, status

from backend.dependencies import CurrentUser, DbDep
from backend.models.plate import Plate
from backend.schemas.plate import PlateRead, OwnershipStatusResponse, PlateVisibilityUpdate

router = APIRouter(prefix="/plates", tags=["ownership"])

# ── Photo storage directory ──────────────────────────────────────────────────
OWNERSHIP_UPLOAD_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "uploads", "ownership")
os.makedirs(OWNERSHIP_UPLOAD_DIR, exist_ok=True)

# ── Constants ────────────────────────────────────────────────────────────────
MAX_PHOTO_SIZE = 10 * 1024 * 1024  # 10 MB
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png"}
MIN_DAY_GAP = timedelta(hours=20)
MAX_DAY_GAP = timedelta(hours=48)


# ── Helpers ──────────────────────────────────────────────────────────────────

async def _get_plate_or_404(plate_id: uuid.UUID, db) -> Plate:
    plate = await db.get(Plate, plate_id)
    if not plate:
        raise HTTPException(status_code=404, detail="Plate not found")
    return plate


def _build_ownership_status(plate: Plate) -> OwnershipStatusResponse:
    """Build an OwnershipStatusResponse from the current plate state."""
    if plate.ownership_verified:
        claim_status = "verified"
    elif plate.ownership_photo_day1_at is not None:
        claim_status = "day1_complete"
    else:
        claim_status = "none"

    return OwnershipStatusResponse(
        plate_id=plate.id,
        status=claim_status,
        day1_submitted_at=plate.ownership_photo_day1_at,
        day2_submitted_at=plate.ownership_photo_day2_at,
        ownership_verified=plate.ownership_verified,
    )


async def _save_photo(plate_id: uuid.UUID, day: int, file: UploadFile) -> str:
    """
    Save an uploaded ownership photo to disk.
    Returns the relative path from the project root.
    """
    plate_dir = os.path.join(OWNERSHIP_UPLOAD_DIR, str(plate_id))
    os.makedirs(plate_dir, exist_ok=True)

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")
    filename = f"day{day}_{timestamp}.jpg"
    filepath = os.path.join(plate_dir, filename)

    contents = await file.read()
    with open(filepath, "wb") as f:
        f.write(contents)

    # Return relative path for DB storage
    return f"uploads/ownership/{plate_id}/{filename}"


async def _validate_photo(photo: UploadFile) -> None:
    """Validate file type and size. Raises HTTPException on failure."""
    if photo.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid file type: {photo.content_type}. Only JPEG and PNG are accepted.",
        )

    # Read content to check size, then seek back to start
    contents = await photo.read()
    if len(contents) > MAX_PHOTO_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File too large ({len(contents)} bytes). Maximum is {MAX_PHOTO_SIZE} bytes (10MB).",
        )
    # Seek back so the file can be read again during save
    await photo.seek(0)


# ── Endpoints ────────────────────────────────────────────────────────────────

@router.post("/{plate_id}/claim/photo", response_model=OwnershipStatusResponse)
async def claim_plate_photo(
    plate_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbDep,
    photo: UploadFile = File(..., description="Ownership verification photo (JPEG/PNG, max 10MB)"),
) -> OwnershipStatusResponse:
    """
    Submit a photo for ownership verification (two-day consecutive flow).

    Day 1: Initiates the claim -- saves the first photo and records the pending user.
    Day 2 (20-48 hours after day 1): Completes verification -- saves second photo,
           sets ownership_verified=True and owner_user_id to the claiming user.

    Returns the current ownership status after processing.
    """
    await _validate_photo(photo)
    plate = await _get_plate_or_404(plate_id, db)
    now = datetime.now(timezone.utc)

    # ── Guard: plate already verified and owned by someone else ──────────
    if (
        plate.owner_user_id is not None
        and plate.ownership_verified
        and plate.owner_user_id != current_user.id
    ):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This plate is already verified and owned by another user.",
        )

    # ── Case A: No pending claim yet → start day-1 ──────────────────────
    if plate.ownership_pending_user_id is None:
        photo_path = await _save_photo(plate_id, day=1, file=photo)

        plate.ownership_pending_user_id = current_user.id
        plate.ownership_photo_day1_path = photo_path
        plate.ownership_photo_day1_at = now
        # Clear any stale day-2 data
        plate.ownership_photo_day2_path = None
        plate.ownership_photo_day2_at = None
        plate.ownership_verified = False

        await db.commit()
        await db.refresh(plate)
        return _build_ownership_status(plate)

    # ── Guard: different user already has a pending claim ────────────────
    if plate.ownership_pending_user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Another user already has a pending ownership claim on this plate.",
        )

    # ── Case B: Same user, day-1 exists → attempt day-2 ─────────────────
    if plate.ownership_photo_day1_at is None:
        # Defensive: pending user set but no day-1 timestamp — restart
        photo_path = await _save_photo(plate_id, day=1, file=photo)
        plate.ownership_photo_day1_path = photo_path
        plate.ownership_photo_day1_at = now
        plate.ownership_photo_day2_path = None
        plate.ownership_photo_day2_at = None
        plate.ownership_verified = False

        await db.commit()
        await db.refresh(plate)
        return _build_ownership_status(plate)

    elapsed = now - plate.ownership_photo_day1_at

    if elapsed < MIN_DAY_GAP:
        remaining_hours = (MIN_DAY_GAP - elapsed).total_seconds() / 3600
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"Too soon. Day-2 photo must be submitted 20-48 hours after day-1. "
                f"Please wait {remaining_hours:.1f} more hours."
            ),
        )

    if elapsed > MAX_DAY_GAP:
        # Window expired — reset and treat this as a fresh day-1
        photo_path = await _save_photo(plate_id, day=1, file=photo)
        plate.ownership_photo_day1_path = photo_path
        plate.ownership_photo_day1_at = now
        plate.ownership_photo_day2_path = None
        plate.ownership_photo_day2_at = None
        plate.ownership_verified = False

        await db.commit()
        await db.refresh(plate)

        return _build_ownership_status(plate)

    # ── Within the 20-48 hour window → complete verification ─────────────
    photo_path = await _save_photo(plate_id, day=2, file=photo)

    plate.ownership_photo_day2_path = photo_path
    plate.ownership_photo_day2_at = now
    plate.ownership_verified = True
    plate.owner_user_id = current_user.id

    await db.commit()
    await db.refresh(plate)
    return _build_ownership_status(plate)


@router.get("/{plate_id}/claim/status", response_model=OwnershipStatusResponse)
async def get_claim_status(
    plate_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbDep,
) -> OwnershipStatusResponse:
    """Return the current ownership/claim status for a plate."""
    plate = await _get_plate_or_404(plate_id, db)
    return _build_ownership_status(plate)


@router.delete("/{plate_id}/claim", status_code=status.HTTP_200_OK)
async def relinquish_plate(
    plate_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbDep,
) -> dict:
    """
    Relinquish ownership of a plate you own.
    Clears owner, verification status, pending user, and all photo references.
    """
    plate = await _get_plate_or_404(plate_id, db)

    if plate.owner_user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not own this plate",
        )

    plate.owner_user_id = None
    plate.ownership_verified = False
    plate.ownership_pending_user_id = None
    plate.ownership_photo_day1_path = None
    plate.ownership_photo_day1_at = None
    plate.ownership_photo_day2_path = None
    plate.ownership_photo_day2_at = None

    await db.commit()
    return {"detail": "Ownership relinquished"}


@router.patch("/{plate_id}/visibility", response_model=PlateRead)
async def update_plate_visibility(
    plate_id: uuid.UUID,
    payload: PlateVisibilityUpdate,
    current_user: CurrentUser,
    db: DbDep,
) -> PlateRead:
    """
    Update visibility controls for an owned plate.
    - is_hidden: hides the plate from public feeds and search
    - is_blocked_readd: prevents other users from re-adding the same plate
    Only the plate owner can update these fields.
    """
    plate = await _get_plate_or_404(plate_id, db)

    if plate.owner_user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the plate owner can update visibility settings",
        )

    if payload.is_hidden is not None:
        plate.is_hidden = payload.is_hidden
    if payload.is_blocked_readd is not None:
        plate.is_blocked_readd = payload.is_blocked_readd

    await db.commit()
    await db.refresh(plate)
    return PlateRead.from_orm_with_vehicle(plate)


@router.post("/{plate_id}/claim/vicroads", status_code=status.HTTP_202_ACCEPTED)
async def claim_with_vicroads(
    plate_id: uuid.UUID,
    current_user: CurrentUser,
    background_tasks: BackgroundTasks,
    db: DbDep,
    screenshot: UploadFile = File(..., description="VicRoads app screenshot showing your plate"),
) -> dict:
    """
    Submit a VicRoads screenshot to claim ownership of a plate.

    Flow:
      1. User uploads VicRoads screenshot showing their plate details.
      2. Screenshot is saved and claim is queued for admin review.
      3. Admin receives email notification and approves/rejects via admin panel.

    If another user already owns the plate, this becomes a dispute claim.
    False declarations result in a ban (per Terms of Service).
    """
    await _validate_photo(screenshot)
    plate = await _get_plate_or_404(plate_id, db)
    now = datetime.now(timezone.utc)

    # Save screenshot
    plate_dir = os.path.join(OWNERSHIP_UPLOAD_DIR, str(plate_id))
    os.makedirs(plate_dir, exist_ok=True)
    timestamp = now.strftime("%Y%m%d%H%M%S")
    filename = f"vicroads_{current_user.id}_{timestamp}.jpg"
    filepath = os.path.join(plate_dir, filename)
    contents = await screenshot.read()
    with open(filepath, "wb") as f:
        f.write(contents)
    screenshot_path = f"uploads/ownership/{plate_id}/{filename}"

    is_dispute = plate.owner_user_id is not None and plate.ownership_verified

    plate.vicroads_screenshot_path = screenshot_path
    plate.vicroads_screenshot_at = now
    if not is_dispute:
        plate.ownership_pending_user_id = current_user.id

    await db.commit()

    # Notify admin
    from backend.services.email import send_admin_moderation_alert
    trigger = "Ownership Dispute" if is_dispute else "Ownership Claim"
    background_tasks.add_task(
        send_admin_moderation_alert,
        trigger=trigger,
        comment_id=str(plate_id),
        plate_text=plate.plate_text,
        author_username=current_user.username,
        comment_body=f"VicRoads screenshot submitted. Dispute: {is_dispute}",
        reason=f"Screenshot path: {screenshot_path}",
    )

    return {
        "detail": "Claim submitted for admin review. You will be notified once approved.",
        "is_dispute": is_dispute,
        "plate_id": str(plate_id),
    }


@router.patch("/{plate_id}/comments/toggle", response_model=PlateRead)
async def toggle_comments(
    plate_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbDep,
) -> PlateRead:
    """Toggle is_comments_open. Only the plate owner can call this."""
    plate = await _get_plate_or_404(plate_id, db)

    if plate.owner_user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the plate owner can toggle comments",
        )

    plate.is_comments_open = not plate.is_comments_open
    await db.commit()
    await db.refresh(plate)
    return PlateRead.from_orm_with_vehicle(plate)
