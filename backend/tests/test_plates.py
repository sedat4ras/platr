"""
Tests: Plate CRUD, duplicate-redirect (HTTP 409), search, spot, ownership.
"""

import pytest
from httpx import AsyncClient


# ── Helpers ───────────────────────────────────────────────────────────────────

async def _create_plate(
    client: AsyncClient,
    headers: dict,
    state: str = "VIC",
    text: str = "TST001",
    style: str = "VIC_STANDARD",
) -> dict:
    resp = await client.post(
        "/api/v1/plates",
        json={
            "state_code": state,
            "plate_text": text,
            "plate_style": style,
            "icon_left": "",
            "icon_right": "",
        },
        headers=headers,
    )
    return resp


# ── Tests ─────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_create_plate_success(client: AsyncClient, auth_headers: dict):
    resp = await _create_plate(client, auth_headers, text="NEWP01")
    assert resp.status_code == 201
    data = resp.json()
    assert data["plateText"] == "NEWP01"
    assert data["stateCode"] == "VIC"
    assert data["vehicle"]["regoStatus"] == "PENDING"


@pytest.mark.asyncio
async def test_create_plate_uppercase(client: AsyncClient, auth_headers: dict):
    """Plate text must be stored uppercased regardless of input."""
    resp = await _create_plate(client, auth_headers, text="lower1")
    assert resp.status_code == 201
    assert resp.json()["plateText"] == "LOWER1"


@pytest.mark.asyncio
async def test_create_plate_duplicate_returns_409(client: AsyncClient, auth_headers: dict):
    """Creating the same [state+text] twice must return HTTP 409 with existing_plate_id."""
    await _create_plate(client, auth_headers, text="DUP001")
    resp = await _create_plate(client, auth_headers, text="DUP001")

    assert resp.status_code == 409
    detail = resp.json()["detail"]
    assert "existing_plate_id" in detail
    assert detail["state_code"] == "VIC"
    assert detail["plate_text"] == "DUP001"


@pytest.mark.asyncio
async def test_get_plate(client: AsyncClient, auth_headers: dict):
    create_resp = await _create_plate(client, auth_headers, text="GETP01")
    plate_id = create_resp.json()["id"]

    resp = await client.get(f"/api/v1/plates/{plate_id}")
    assert resp.status_code == 200
    assert resp.json()["id"] == plate_id


@pytest.mark.asyncio
async def test_list_plates_filter_by_state(client: AsyncClient, auth_headers: dict):
    await _create_plate(client, auth_headers, state="VIC", text="LIST01")
    await _create_plate(client, auth_headers, state="NSW", text="LIST02")

    resp = await client.get("/api/v1/plates?state_code=NSW")
    assert resp.status_code == 200
    plates = resp.json()
    assert all(p["stateCode"] == "NSW" for p in plates)


@pytest.mark.asyncio
async def test_search_plates(client: AsyncClient, auth_headers: dict):
    await _create_plate(client, auth_headers, text="SRCH01")
    await _create_plate(client, auth_headers, text="SRCH02")
    await _create_plate(client, auth_headers, text="OTHER1")

    resp = await client.get("/api/v1/plates/search?q=SRCH")
    assert resp.status_code == 200
    results = resp.json()
    assert len(results) >= 2
    assert all("SRCH" in p["plateText"] for p in results)


@pytest.mark.asyncio
async def test_spot_plate(client: AsyncClient, auth_headers: dict):
    create_resp = await _create_plate(client, auth_headers, text="SPOT01")
    plate_id = create_resp.json()["id"]

    before = await client.get(f"/api/v1/plates/{plate_id}")
    before_count = before.json()["spotCount"]

    spot_resp = await client.post(f"/api/v1/plates/{plate_id}/spot", headers=auth_headers)
    assert spot_resp.status_code == 200
    assert spot_resp.json()["spot_count"] == before_count + 1


@pytest.mark.asyncio
async def test_claim_plate(client: AsyncClient, auth_headers: dict):
    create_resp = await _create_plate(client, auth_headers, text="CLAM01")
    plate_id = create_resp.json()["id"]

    resp = await client.post(f"/api/v1/plates/{plate_id}/claim", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["ownerUserId"] is not None


@pytest.mark.asyncio
async def test_toggle_comments(client: AsyncClient, auth_headers: dict):
    create_resp = await _create_plate(client, auth_headers, text="CMMNT1")
    plate_id = create_resp.json()["id"]

    # Claim the plate first
    await client.post(f"/api/v1/plates/{plate_id}/claim", headers=auth_headers)

    # Toggle comments off
    resp = await client.patch(
        f"/api/v1/plates/{plate_id}/comments/toggle", headers=auth_headers
    )
    assert resp.status_code == 200
    assert resp.json()["isCommentsOpen"] is False

    # Toggle back on
    resp2 = await client.patch(
        f"/api/v1/plates/{plate_id}/comments/toggle", headers=auth_headers
    )
    assert resp2.json()["isCommentsOpen"] is True


@pytest.mark.asyncio
async def test_update_plate_unauthorized(client: AsyncClient, auth_headers: dict):
    """A non-owner cannot update a plate."""
    create_resp = await _create_plate(client, auth_headers, text="AUTH01")
    plate_id = create_resp.json()["id"]

    # Register second user
    reg = await client.post(
        "/api/v1/auth/register",
        json={"username": "other", "email": "other@platr.app", "password": "pass1234"},
    )
    other_token = reg.json()["access_token"]
    other_headers = {"Authorization": f"Bearer {other_token}"}

    # Try to claim (should succeed since unclaimed)
    await client.post(f"/api/v1/plates/{plate_id}/claim", headers=auth_headers)

    # Other user tries to update — should fail
    resp = await client.patch(
        f"/api/v1/plates/{plate_id}",
        json={"plate_style": "VIC_CUSTOM_BLACK"},
        headers=other_headers,
    )
    assert resp.status_code == 403
