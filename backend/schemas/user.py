# Copyright (c) 2025 Sedat Aras — Platr. MIT License.
"""
Platr Backend — User Pydantic schemas.
[FastAPIDBAgent | BE-002]
"""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, EmailStr, Field


class UserCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=50, pattern=r"^[a-zA-Z0-9_]+$")
    email: EmailStr
    password: str = Field(..., min_length=8)
    display_name: str | None = Field(None, max_length=100)
    date_of_birth: str | None = Field(None, description="YYYY-MM-DD, must be 16+ years old")


class UserRead(BaseModel):
    id: uuid.UUID
    username: str
    display_name: str | None
    avatar_url: str | None = None
    is_verified: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    user_id: uuid.UUID | None = None
