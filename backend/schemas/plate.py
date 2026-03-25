# Copyright (c) 2025 Sedat Aras — Platr. MIT License.
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
            if ch.isalnum() or ch == "
