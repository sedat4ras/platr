# Copyright (c) 2025 Sedat Aras — Platr. MIT License.
"""
Platr Backend — Auth Router.
POST /auth/register  → Create account
POST /auth/login     → Email + password → access + refresh tokens
POST /auth/refresh   → Exchange refresh token for new access token
GET  /auth/me        → Current user profile
PATCH /auth/me       → Update display_name / bio
"""

from __future__ import annotations

import logging
import secrets
import string
from datetime import date, datetime, timedelta, timezone

from fastapi import APIRouter, BackgroundTasks, HTTPException, UploadFile, status
from sqlalchemy import select

from backend.auth import (
    create_access_token,
    create_refresh_token,
    decode_token,
    extract_user_id,
    hash_password,
    verify_password,
)
from backend.dependencies import CurrentUser, DbDep
from backend.models.user import User
from backend.schemas.user import Token, UserCreate, UserRead
from pydantic import BaseModel, EmailStr, Field

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["auth"])


# ── Schemas (auth-specific, small enough to inline here) ─────────────────────

class LoginRequest(BaseModel):
    login: str      # accepts email address OR username
    password: str


class RefreshRequest(BaseModel):
    refresh_token: str


class UserUpdateRequest(BaseModel):
    display_name: str | None = None
    bio: str | None = None


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


# ── Endpoints ─────────────────────────────────────────────────────────────────

def _generate_otp() -> str:
    """Return a random 6-digit verification code."""
    return f"{secrets.randbelow(1_000_000):06d}"


@router.post("/register", status_code=status.HTTP_201_CREATED, response_model=TokenPair)
async def register(
    payload: UserCreate,
    background_tasks: BackgroundTasks,
    db: DbDep,
) -> TokenPair:
    """Register a new account. Returns tokens immediately; email verification required before full access."""
    from backend.services.email import send_verification_email

    # ── Age verification (Australian Social Media Minimum Age law) ──────────
    if payload.date_of_birth:
        try:
            dob = date.fromisoformat(payload.date_of_birth)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid date_of_birth format. Use YYYY-MM-DD.",
            )
        today = date.today()
        age = today.year - dob.year - ((today.month, today.day) < (dob.month, dob.day))
        if age < 16:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You must be at least 16 years old to create an account.",
            )

    existing = await db.scalar(
        select(User).where(
            (User.username == payload.username) | (User.email == payload.email)
        )
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Username or email already registered",
        )

    code = _generate_otp()
    dob_dt = None
    if payload.date_of_birth:
        dob_dt = datetime.combine(date.fromisoformat(payload.date_of_birth), datetime.min.time(), tzinfo=timezone.utc)

    user = User(
        username=payload.username,
        email=str(payload.email),
        hashed_password=hash_password(payload.password),
        display_name=payload.display_name,
        date_of_birth=dob_dt,
        is_verified=False,
        email_verification_code=code,
        email_verification_expires_at=datetime.now(timezone.utc) + timedelta(minutes=15),
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    background_tasks.add_task(send_verification_email, str(payload.email), code)

    return TokenPair(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
    )


@router.post("/login", response_model=TokenPair)
async def login(payload: LoginRequest, db: DbDep) -> TokenPair:
    """Authenticate with email OR username + password, return token pair."""
    from sqlalchemy import or_ as sql_or
    user = await db.scalar(
        select(User).where(
            sql_or(User.email == payload.login, User.username == payload.login)
        )
    )

    if not user or not user.hashed_password or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username/email or password",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is disabled",
        )

    return TokenPair(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
    )


class VerifyEmailRequest(BaseModel):
    email: EmailStr
    code: str


class VerifyEmailResponse(BaseModel):
    verified: bool


@router.post("/verify-email", response_model=VerifyEmailResponse)
async def verify_email(payload: VerifyEmailRequest, db: DbDep) -> VerifyEmailResponse:
    """Verify the 6-digit OTP sent to the user's email after registration."""
    user = await db.scalar(select(User).where(User.email == str(payload.email)))

    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    if user.is_verified:
        return VerifyEmailResponse(verified=True)

    now = datetime.now(timezone.utc)
    if (
        user.email_verification_code != payload.code
        or user.email_verification_expires_at is None
        or user.email_verification_expires_at < now
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired verification code",
        )

    user.is_verified = True
    user.email_verification_code = None
    user.email_verification_expires_at = None
    await db.commit()

    return VerifyEmailResponse(verified=True)


class ResendVerificationRequest(BaseModel):
    email: EmailStr


@router.post("/resend-verification", status_code=status.HTTP_200_OK)
async def resend_verification(
    payload: ResendVerificationRequest,
    background_tasks: BackgroundTasks,
    db: DbDep,
) -> dict:
    """Generate a new OTP and resend the verification email."""
    from backend.services.email import send_verification_email

    user = await db.scalar(select(User).where(User.email == str(payload.email)))
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    if user.is_verified:
        return {"sent": False, "reason": "already_verified"}

    code = _generate_otp()
    user.email_verification_code = code
    user.email_verification_expires_at = datetime.now(timezone.utc) + timedelta(minutes=15)
    await db.commit()

    background_tasks.add_task(send_verification_email, str(payload.email), code)
    return {"sent": True}


@router.post("/refresh", response_model=Token)
async def refresh_token(payload: RefreshRequest, db: DbDep) -> Token:
    """Exchange a valid refresh token for a new access token."""
    from jose import JWTError

    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid refresh token",
    )

    try:
        data = decode_token(payload.refresh_token)
        if data.get("type") != "refresh":
            raise credentials_exception
        user_id = extract_user_id(payload.refresh_token)
    except (JWTError, ValueError):
        raise credentials_exception

    user = await db.get(User, user_id)
    if not user or not user.is_active:
        raise credentials_exception

    return Token(access_token=create_access_token(user.id))


@router.get("/me", response_model=UserRead)
async def get_me(current_user: CurrentUser) -> UserRead:
    """Return the authenticated user's profile."""
    return UserRead.model_validate(current_user)


class GoogleAuthRequest(BaseModel):
    id_token: str


@router.post("/google", response_model=TokenPair)
async def google_sign_in(payload: GoogleAuthRequest, db: DbDep) -> TokenPair:
    """
    Verify a Google ID token from iOS and return a Platr token pair.

    Flow:
      1. Verify ID token signature + audience with google-auth
      2. Extract google_id, email, name, picture
      3. Find user by google_id → found → return tokens
      4. Find user by email → found → link google_id + avatar → return tokens
      5. No match → auto-create account → return tokens
    """
    import random
    import re
    import string

    from google.auth.transport import requests as google_requests
    from google.oauth2 import id_token as google_id_token

    from backend.config import settings

    client_id = settings.google_ios_client_id
    if not client_id:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Google Sign-In is not configured on this server",
        )

    # ── 1. Verify token ───────────────────────────────────────────────────────
    try:
        id_info = google_id_token.verify_oauth2_token(
            payload.id_token,
            google_requests.Request(),
            audience=client_id,
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Google ID token: {exc}",
        )

    google_sub  = id_info["sub"]           # stable unique ID
    email       = id_info.get("email", "")
    name        = id_info.get("name", "")
    picture_url = id_info.get("picture", "")

    # ── 2. Find by google_id ──────────────────────────────────────────────────
    user = await db.scalar(select(User).where(User.google_id == google_sub))

    # ── 3. Find by email (account linking) ───────────────────────────────────
    if not user and email:
        user = await db.scalar(select(User).where(User.email == email))
        if user:
            user.google_id  = google_sub
            user.avatar_url = picture_url or user.avatar_url
            user.is_verified = True
            await db.commit()

    # ── 4. Auto-create new account ────────────────────────────────────────────
    if not user:
        # Derive a base username from email prefix
        base = re.sub(r"[^a-zA-Z0-9_]", "_", (email.split("@")[0] if email else "user"))[:40]
        # Ensure uniqueness
        username = base
        while await db.scalar(select(User).where(User.username == username)):
            suffix = "".join(secrets.choice(string.digits) for _ in range(4))
            username = f"{base[:45]}_{suffix}"

        user = User(
            username=username,
            email=email,
            hashed_password=None,
            display_name=name or username,
            google_id=google_sub,
            avatar_url=picture_url,
            is_verified=True,  # Google accounts are pre-verified
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is disabled")

    return TokenPair(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
    )


# ── Apple Sign-In ─────────────────────────────────────────────────────────────


class AppleAuthRequest(BaseModel):
    identity_token: str
    full_name: str | None = None  # only sent on first sign-in


@router.post("/apple", response_model=TokenPair)
async def apple_sign_in(payload: AppleAuthRequest, db: DbDep) -> TokenPair:
    """
    Verify an Apple identity token (JWT) and return a Platr token pair.

    Flow:
      1. Fetch Apple's JWKS public keys
      2. Decode and verify the identity token (RS256)
      3. Extract sub (Apple user ID) + email
      4. Find/create/link user
    """
    import random
    import re
    import string

    import httpx
    from jose import jwt as jose_jwt

    from backend.config import settings

    APPLE_JWKS_URL = "https://appleid.apple.com/auth/keys"
    APPLE_ISSUER = "https://appleid.apple.com"

    # ── 1. Get unverified header to find key ID ────────────────────────────
    try:
        header = jose_jwt.get_unverified_header(payload.identity_token)
        kid = header["kid"]
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Apple identity token format",
        )

    # ── 2. Fetch Apple's JWKS ──────────────────────────────────────────────
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(APPLE_JWKS_URL, timeout=10)
            keys = resp.json()["keys"]
    except Exception as exc:
        logger.error(f"Failed to fetch Apple JWKS: {exc}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not verify Apple token at this time",
        )

    # ── 3. Find matching key ───────────────────────────────────────────────
    apple_key = None
    for key in keys:
        if key["kid"] == kid:
            apple_key = key
            break

    if not apple_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Apple public key not found for this token",
        )

    # ── 4. Verify and decode ───────────────────────────────────────────────
    try:
        claims = jose_jwt.decode(
            payload.identity_token,
            apple_key,
            algorithms=["RS256"],
            audience=settings.apple_bundle_id,
            issuer=APPLE_ISSUER,
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Apple identity token: {exc}",
        )

    apple_sub = claims["sub"]
    email = claims.get("email", "")

    # ── 5. Find by apple_id ────────────────────────────────────────────────
    user = await db.scalar(select(User).where(User.apple_id == apple_sub))

    # ── 6. Find by email (account linking) ─────────────────────────────────
    if not user and email:
        user = await db.scalar(select(User).where(User.email == email))
        if user:
            user.apple_id = apple_sub
            user.is_verified = True
            await db.commit()

    # ── 7. Auto-create new account ─────────────────────────────────────────
    if not user:
        base = re.sub(r"[^a-zA-Z0-9_]", "_", (email.split("@")[0] if email else "apple_user"))[:40]
        username = base
        while await db.scalar(select(User).where(User.username == username)):
            suffix = "".join(secrets.choice(string.digits) for _ in range(4))
            username = f"{base[:45]}_{suffix}"

        user = User(
            username=username,
            email=email or f"apple_{apple_sub[:12]}@private.platr.app",
            hashed_password=None,
            display_name=payload.full_name or username,
            apple_id=apple_sub,
            is_verified=True,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is disabled")

    return TokenPair(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
    )


# ── Password Reset ────────────────────────────────────────────────────────────


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


@router.post("/forgot-password")
async def forgot_password(
    payload: ForgotPasswordRequest,
    background_tasks: BackgroundTasks,
    db: DbDep,
) -> dict:
    """Send a 6-digit password reset code to the user's email."""
    from backend.services.email import send_password_reset_email

    user = await db.scalar(select(User).where(User.email == str(payload.email)))
    # Always return success to prevent email enumeration
    if not user:
        return {"sent": True}

    if not user.hashed_password:
        # Google-only account — no password to reset
        return {"sent": True}

    code = _generate_otp()
    user.password_reset_code = code
    user.password_reset_expires_at = datetime.now(timezone.utc) + timedelta(minutes=15)
    await db.commit()

    background_tasks.add_task(send_password_reset_email, str(payload.email), code)
    return {"sent": True}


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    code: str
    new_password: str = Field(..., min_length=8)


@router.post("/reset-password")
async def reset_password(payload: ResetPasswordRequest, db: DbDep) -> dict:
    """Validate the reset code and set a new password."""
    user = await db.scalar(select(User).where(User.email == str(payload.email)))
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    now = datetime.now(timezone.utc)
    if (
        user.password_reset_code != payload.code
        or user.password_reset_expires_at is None
        or user.password_reset_expires_at < now
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired reset code",
        )

    user.hashed_password = hash_password(payload.new_password)
    user.password_reset_code = None
    user.password_reset_expires_at = None
    await db.commit()

    return {"reset": True}


@router.patch("/me", response_model=UserRead)
async def update_me(
    payload: UserUpdateRequest,
    current_user: CurrentUser,
    db: DbDep,
) -> UserRead:
    """Update display_name or bio."""
    if payload.display_name is not None:
        current_user.display_name = payload.display_name
    if payload.bio is not None:
        current_user.bio = payload.bio

    await db.commit()
    await db.refresh(current_user)
    return UserRead.model_validate(current_user)


# ── Avatar Upload ─────────────────────────────────────────────────────────────

_UPLOAD_DIR = "uploads/avatars"
_MAX_AVATAR_SIZE = 5 * 1024 * 1024  # 5 MB
_ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp"}


@router.post("/me/avatar", response_model=UserRead)
async def upload_avatar(
    file: UploadFile,
    current_user: CurrentUser,
    db: DbDep,
) -> UserRead:
    """Upload a profile avatar image (max 5 MB, JPEG/PNG/WebP)."""
    import os
    import uuid as _uuid

    if file.content_type not in _ALLOWED_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported file type: {file.content_type}. Use JPEG, PNG, or WebP.",
        )

    data = await file.read()
    if len(data) > _MAX_AVATAR_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="File too large. Maximum size is 5 MB.",
        )

    os.makedirs(_UPLOAD_DIR, exist_ok=True)

    ext = file.filename.rsplit(".", 1)[-1] if file.filename and "." in file.filename else "jpg"
    filename = f"{_uuid.uuid4().hex}.{ext}"
    filepath = os.path.join(_UPLOAD_DIR, filename)

    with open(filepath, "wb") as f:
        f.write(data)

    from backend.config import settings
    base = settings.api_base_url.rstrip("/") if hasattr(settings, "api_base_url") else ""
    current_user.avatar_url = f"/uploads/avatars/{filename}" if not base else f"{base}/uploads/avatars/{filename}"

    await db.commit()
    await db.refresh(current_user)
    return UserRead.model_validate(current_user)


# ── Device Token (Push Notifications) ─────────────────────────────────────────


class DeviceTokenRequest(BaseModel):
    device_token: str
    platform: str = "ios"


@router.post("/me/device-token")
async def register_device_token(
    payload: DeviceTokenRequest,
    current_user: CurrentUser,
    db: DbDep,
) -> dict:
    """Store device token for push notifications."""
    # Store in user model (simple approach — for scale, use a separate table)
    current_user.device_token = payload.device_token
    await db.commit()
    return {"registered": True}


# ── Delete Account ────────────────────────────────────────────────────────────


@router.delete("/me", status_code=status.HTTP_200_OK)
async def delete_account(current_user: CurrentUser, db: DbDep) -> dict:
    """
    Permanently delete the current user's account (Apple requirement).
    Anonymizes all personal data while preserving referential integrity.
    """
    current_user.is_active = False
    current_user.email = f"deleted_{current_user.id}@deleted.platr.app"
    current_user.username = f"deleted_{str(current_user.id)[:8]}"
    current_user.display_name = "Deleted User"
    current_user.bio = None
    current_user.avatar_url = None
    current_user.google_id = None
    current_user.apple_id = None
    current_user.hashed_password = None
    current_user.date_of_birth = None
    current_user.device_token = None
    current_user.email_verification_code = None
    current_user.email_verification_expires_at = None
    current_user.password_reset_code = None
    current_user.password_reset_expires_at = None

    await db.commit()
    return {"deleted": True}
