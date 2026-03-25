"""
Platr Backend — FastAPI shared dependencies.
Injects the current authenticated user into route handlers.
"""

from __future__ import annotations

import uuid
from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError
from sqlalchemy.ext.asyncio import AsyncSession

from backend.auth import extract_user_id
from backend.database import get_db
from backend.models.user import User

_bearer = HTTPBearer(auto_error=True)


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(_bearer)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    """
    Dependency that validates the Bearer JWT and returns the User ORM object.
    Raises HTTP 401 if token is missing, invalid, or the user no longer exists.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        user_id: uuid.UUID = extract_user_id(credentials.credentials)
    except (JWTError, ValueError):
        raise credentials_exception

    user = await db.get(User, user_id)
    if user is None or not user.is_active:
        raise credentials_exception

    return user


async def get_current_user_optional(
    db: Annotated[AsyncSession, Depends(get_db)],
    credentials: HTTPAuthorizationCredentials | None = Depends(
        HTTPBearer(auto_error=False)
    ),
) -> User | None:
    """
    Optional auth dependency — returns None instead of raising 401.
    Used for endpoints that behave differently for anonymous vs logged-in users.
    """
    if credentials is None:
        return None
    try:
        user_id = extract_user_id(credentials.credentials)
        return await db.get(User, user_id)
    except Exception:
        return None


# Convenience type aliases for route handlers
CurrentUser         = Annotated[User, Depends(get_current_user)]
CurrentUserOptional = Annotated[User | None, Depends(get_current_user_optional)]
DbDep               = Annotated[AsyncSession, Depends(get_db)]
