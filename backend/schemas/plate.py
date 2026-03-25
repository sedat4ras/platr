"""
Platr Backend — Plate Pydantic schemas (request / response).
[FastAPIDBAgent | BE-002]
"""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field, field_validator

from backend.models.plate import PlateStyle, RegoStatus


class PlateCreate(BaseModel):
    state_code: str = Field(..., min_length=2, max_length=10, examples=["VIC"])
    plate_text: str = Field(..., min_length=1, max_length=8, examples=["ABC123"])
    plate_style: PlateStyle = PlateStyle.VIC_STANDARD
    has_space_separator: bool = True
    custom_bg_color: str | None = None
    custom_config: dict | None = None

    @field_validator("plate_text", mode="before")
    @classmethod
    def uppercase_plate(cls, v: str) -> str:
        # Keep ★ (U+2605) icon marker, strip other special chars
        cleaned = ""
        for ch in v.upper().strip():
            if ch.isalnum() or ch == "\u2605":
                cleaned += ch
        # Max 2 ★ markers
        star_count = cleaned.count("\u2605")
        if star_count > 2:
            raise ValueError("Maximum 2 icon markers (★) allowed")
        return cleaned

    @field_validator("state_code", mode="before")
    @classmethod
    def uppercase_state(cls, v: str) -> str:
        return v.upper().strip()


class ClaimRequest(BaseModel):
    """Legacy VIN-based claim (kept for backward compat)."""
    vin_last6: str = Field(..., min_length=6, max_length=6, pattern=r"^[A-Za-z0-9]{6}$")

    @field_validator("vin_last6", mode="before")
    @classmethod
    def uppercase_vin(cls, v: str) -> str:
        return v.upper().strip()


class PlateUpdate(BaseModel):
    plate_style: PlateStyle | None = None
    is_comments_open: bool | None = None
    has_space_separator: bool | None = None
    custom_bg_color: str | None = None
    custom_config: dict | None = None


class PlateVisibilityUpdate(BaseModel):
    is_hidden: bool | None = None
    is_blocked_readd: bool | None = None


class VehicleDetails(BaseModel):
    """Vehicle info from RegoCheck OSINT — may be null until populated."""
    vehicle_year: int | None = None
    vehicle_make: str | None = None
    vehicle_model: str | None = None
    vehicle_color: str | None = None
    rego_status: RegoStatus = RegoStatus.PENDING
    rego_expiry_date: datetime | None = None
    rego_checked_at: datetime | None = None


class OwnershipStatusResponse(BaseModel):
    plate_id: uuid.UUID
    status: str  # "none", "day1_complete", "verified"
    day1_submitted_at: datetime | None = None
    day2_submitted_at: datetime | None = None
    ownership_verified: bool = False


class PlateRead(BaseModel):
    id: uuid.UUID
    state_code: str
    plate_text: str
    plate_style: PlateStyle
    is_comments_open: bool
    star_count: int
    view_count: int
    owner_user_id: uuid.UUID | None
    submitted_by_user_id: uuid.UUID | None
    submitted_by_username: str | None = None
    vehicle: VehicleDetails
    has_space_separator: bool = True
    custom_bg_color: str | None = None
    custom_config: str | None = None
    plate_photo_path: str | None = None
    is_hidden: bool = False
    is_blocked_readd: bool = False
    ownership_verified: bool = False
    ownership_status: str = "none"
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}

    @classmethod
    def from_orm_with_vehicle(cls, plate: object) -> "PlateRead":
        # Compute ownership status
        ownership_status = "none"
        if getattr(plate, "ownership_verified", False):
            ownership_status = "verified"
        elif getattr(plate, "ownership_photo_day1_at", None) is not None:
            ownership_status = "day1_complete"

        data = {
            "id": plate.id,
            "state_code": plate.state_code,
            "plate_text": plate.plate_text,
            "plate_style": plate.plate_style,
            "is_comments_open": plate.is_comments_open,
            "star_count": getattr(plate, "star_count", 0),
            "view_count": plate.view_count,
            "owner_user_id": plate.owner_user_id,
            "submitted_by_user_id": plate.submitted_by_user_id,
            "submitted_by_username": getattr(plate.submitter, "username", None) if hasattr(plate, "submitter") else None,
            "has_space_separator": getattr(plate, "has_space_separator", True),
            "custom_bg_color": getattr(plate, "custom_bg_color", None),
            "custom_config": getattr(plate, "custom_config", None),
            "plate_photo_path": getattr(plate, "plate_photo_path", None),
            "is_hidden": getattr(plate, "is_hidden", False),
            "is_blocked_readd": getattr(plate, "is_blocked_readd", False),
            "ownership_verified": getattr(plate, "ownership_verified", False),
            "ownership_status": ownership_status,
            "created_at": plate.created_at,
            "updated_at": plate.updated_at,
            "vehicle": VehicleDetails(
                vehicle_year=plate.vehicle_year,
                vehicle_make=plate.vehicle_make,
                vehicle_model=plate.vehicle_model,
                vehicle_color=plate.vehicle_color,
                rego_status=plate.rego_status,
                rego_expiry_date=plate.rego_expiry_date,
                rego_checked_at=plate.rego_checked_at,
            ),
        }
        return cls(**data)


class DuplicatePlateResponse(BaseModel):
    """
    Returned as HTTP 409 when a plate with the same state+text already exists.
    iOS client uses existing_plate_id to navigate to the existing plate's view.
    """
    detail: str = "Plate already exists"
    existing_plate_id: uuid.UUID
    state_code: str
    plate_text: str
