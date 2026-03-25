# Copyright (c) 2025 Sedat Aras — Platr. MIT License.
"""
Tests: Auth endpoints (register, login, refresh, /me).
"""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_register_success(client: AsyncClient):
    resp = await client.post(
        "/api/v1/auth/register",
        json={
            "username": "newuser",
            "email": "new@platr.app",
            "password": "securepass1",
        },
    )
    assert resp.status_code == 201
    data = resp.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_register_duplicate(client: AsyncClient, auth_headers: dict):
    resp = await client.post(
        "/api/v1/auth/register",
        json={
            "username": "testuser",       # already created in auth_headers fixture
            "email": "test@platr.app",
            "password": "password123",
        },
    )
    assert resp.status_code == 409


@pytest.mark.asyncio
async def test_login_success(client: AsyncClient, auth_headers: dict):
    resp = await client.post(
        "/api/v1/auth/login",
        json={"email": "test@platr.app", "password": "password123"},
    )
    assert resp.status_code == 200
    assert "access_token" in resp.json()


@pytest.mark.asyncio
async def test_login_wrong_password(client: AsyncClient, auth_headers: dict):
    resp = await client.post(
        "/api/v1/auth/login",
        json={"email": "test@platr.app", "password": "wrongpassword"},
    )
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_get_me(client: AsyncClient, auth_headers: dict):
    resp = await client.get("/api/v1/auth/me", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["username"] == "testuser"


@pytest.mark.asyncio
async def test_get_me_no_token(client: AsyncClient):
    resp = await client.get("/api/v1/auth/me")
    assert resp.status_code == 403  # HTTPBearer returns 403 when no creds


@pytest.mark.asyncio
async def test_refresh_token(client: AsyncClient):
    reg = await client.post(
        "/api/v1/auth/register",
        json={
            "username": "refreshuser",
            "email": "refresh@platr.app",
            "password": "password123",
        },
    )
    refresh_token = reg.json()["refresh_token"]

    resp = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token},
    )
    assert resp.status_code == 200
    assert "access_token" in resp.json()
