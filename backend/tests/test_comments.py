"""
Tests: Comments CRUD, UGC Report/Block, soft-delete, auto-hide.
"""

import pytest
from httpx import AsyncClient


async def _make_plate_and_comment(client: AsyncClient, headers: dict) -> tuple[str, str]:
    """Helper: create a plate and a comment, return (plate_id, comment_id)."""
    plate_resp = await client.post(
        "/api/v1/plates",
        json={
            "state_code": "VIC",
            "plate_text": f"CM{id(headers):04X}"[:6],
            "plate_style": "VIC_STANDARD",
            "icon_left": "",
            "icon_right": "",
        },
        headers=headers,
    )
    plate_id = plate_resp.json()["id"]

    comment_resp = await client.post(
        f"/api/v1/plates/{plate_id}/comments",
        json={"body": "Great plate!"},
        headers=headers,
    )
    assert comment_resp.status_code == 201
    comment_id = comment_resp.json()["id"]
    return plate_id, comment_id


@pytest.mark.asyncio
async def test_create_comment(client: AsyncClient, auth_headers: dict):
    plate_resp = await client.post(
        "/api/v1/plates",
        json={"state_code": "VIC", "plate_text": "CMNT10", "plate_style": "VIC_STANDARD",
              "icon_left": "", "icon_right": ""},
        headers=auth_headers,
    )
    plate_id = plate_resp.json()["id"]

    resp = await client.post(
        f"/api/v1/plates/{plate_id}/comments",
        json={"body": "Nice plate!"},
        headers=auth_headers,
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["body"] == "Nice plate!"
    assert data["reportCount"] == 0


@pytest.mark.asyncio
async def test_report_comment(client: AsyncClient, auth_headers: dict):
    _, comment_id = await _make_plate_and_comment(client, auth_headers)

    resp = await client.post(
        f"/api/v1/comments/{comment_id}/report",
        json={"reason": "Spam"},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    assert resp.json()["report_count"] == 1


@pytest.mark.asyncio
async def test_block_author(client: AsyncClient, auth_headers: dict):
    _, comment_id = await _make_plate_and_comment(client, auth_headers)

    resp = await client.post(
        f"/api/v1/comments/{comment_id}/block",
        json={},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    assert "blocked" in resp.json()["detail"].lower()


@pytest.mark.asyncio
async def test_soft_delete_comment(client: AsyncClient, auth_headers: dict):
    plate_id, comment_id = await _make_plate_and_comment(client, auth_headers)

    del_resp = await client.delete(
        f"/api/v1/comments/{comment_id}", headers=auth_headers
    )
    assert del_resp.status_code == 200

    # Comment should no longer appear in list (soft-deleted)
    list_resp = await client.get(f"/api/v1/plates/{plate_id}/comments")
    ids = [c["id"] for c in list_resp.json()]
    assert comment_id not in ids


@pytest.mark.asyncio
async def test_closed_plate_blocks_comments(client: AsyncClient, auth_headers: dict):
    plate_resp = await client.post(
        "/api/v1/plates",
        json={"state_code": "VIC", "plate_text": "CLSD01", "plate_style": "VIC_STANDARD",
              "icon_left": "", "icon_right": ""},
        headers=auth_headers,
    )
    plate_id = plate_resp.json()["id"]

    # Claim + close comments
    await client.post(f"/api/v1/plates/{plate_id}/claim", headers=auth_headers)
    await client.patch(f"/api/v1/plates/{plate_id}/comments/toggle", headers=auth_headers)

    resp = await client.post(
        f"/api/v1/plates/{plate_id}/comments",
        json={"body": "This should fail"},
        headers=auth_headers,
    )
    assert resp.status_code == 403
