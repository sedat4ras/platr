# Copyright (c) 2025 Sedat Aras — Platr. MIT License.
"""
Platr Backend — Plate Pydantic schemas (request / response).
[FastAPIDBAgent | BE-002]
"""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field, field_validator

from backend.models.plate import PlateStyle


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
        return v.upper().strip()

    @field_validator("state_code", mode="before")
    @classmethod
    def uppercase_state(cls, v: str) -> str:
        return v.upper().strip()


class PlateUpdate(BaseModel):
    plate_style: PlateStyle | None = None
    custom_config: dict | None = None
    is_comments_open: bool | None = None


class DuplicatePlateResponse(BaseModel):
    existing_plate_id: uuid.UUID
    state_code: str
    plate_text: str


class PlateRead(BaseModel):
    id: uuid.UUID
    state_code: str
    plate_text: str
    plate_style: PlateStyle
    custom_config: str | None
    has_space_separator: bool
    custom_bg_color: str | None
    star_count: int
    view_count: int
    is_comments_open: bool
    owner_user_id: uuid.UUID | None
    submitted_by_user_id: uuid.UUID | None
    submitted_by_username: str | None
    plate_photo_path: str | None
    ownership_verified: bool
    is_hidden: bool
    is_blocked_readd: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}

    @classmethod
    def from_orm_with_vehicle(cls, plate: object) -> "PlateRead":
        """Build PlateRead from a Plate ORM object."""
        submitted_by_username: str | None = None
        if hasattr(plate, "submitter") and plate.submitter is not None:
            submitted_by_username = plate.submitter.username

        return cls(
            id=plate.id,
            state_code=plate.state_code,
            plate_text=plate.plate_text,
            plate_style=plate.plate_style,
            custom_config=plate.custom_config,
            has_space_separator=plate.has_space_separator,
            custom_bg_color=plate.custom_bg_color,
            star_count=plate.star_count,
            view_count=plate.view_count,
            is_comments_open=plate.is_comments_open,
            owner_user_id=plate.owner_user_id,
            submitted_by_user_id=plate.submitted_by_user_id,
            submitted_by_username=submitted_by_username,
            plate_photo_path=plate.plate_photo_path,
            ownership_verified=plate.ownership_verified,
            is_hidden=plate.is_hidden,
            is_blocked_readd=plate.is_blocked_readd,
            created_at=plate.created_at,
            updated_at=plate.updated_at,
        )
