# Copyright (c) 2025 Sedat Aras - Platr. MIT License.
"""
Platr Backend — VicRoads RegoCheck OSINT Service.
[OSINTAgent | OSINT-001]

Strategy:
  1. Selenium (headless Chrome) — bypasses bot protection, fills real form
  2. Graceful fallback: mark rego_status = UNKNOWN

Rate limiting: min 5 seconds between requests.
All scraping is based on publicly available data from VicRoads.
"""

from __future__ import annotations

import asyncio
import concurrent.futures
import hashlib
import logging
import re
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone

from backend.config import settings

logger = logging.getLogger(__name__)

VICROADS_REGO_URL = (
    "https://www.vicroads.vic.gov.au/registration/buy-sell-or-transfer-a-vehicle"
    "/check-vehicle-registration/vehicle-registration-enquiry"
)

_last_request_at: float = 0.0
_executor = concurrent.futures.ThreadPoolExecutor(max_workers=2)


@dataclass
class RegoResult:
    state_code: str
    plate_text: str
    rego_status: str           # CURRENT | EXPIRED | CANCELLED | UNKNOWN
    vehicle_year: int | None
    vehicle_make: str | None
    vehicle_model: str | None
    vehicle_color: str | None
    rego_expiry_date: datetime | None
    raw_hash: str


async def _rate_limit() -> None:
    global _last_request_at
    now = asyncio.get_event_loop().time()
    elapsed = now - _last_request_at
    wait = settings.rego_check_rate_limit_seconds - elapsed
    if wait > 0:
        logger.debug(f"[RegoCheck] Rate limiting: sleeping {wait:.2f}s")
        await asyncio.sleep(wait)
    _last_request_at = asyncio.get_event_loop().time()


def _selenium_scrape_sync(plate_text: str) -> dict | None:
    """
    Synchronous Selenium scraper — runs in a ThreadPoolExecutor.
    Opens headless Chrome, fills the VicRoads registration enquiry form,
    and extracts dl/dt/dd result pairs from the results page.
    """
    import time
    from selenium import webdriver
    from selenium.webdriver.chrome.options import Options
    from selenium.webdriver.chrome.service import Service
    from selenium.webdriver.common.by import By
    from selenium.webdriver.support.ui import WebDriverWait
    from selenium.webdriver.support import expected_conditions as EC
    from webdriver_manager.chrome import ChromeDriverManager

    opts = Options()
    opts.add_argument("--headless=new")
    opts.add_argument("--no-sandbox")
    opts.add_argument("--disable-dev-shm-usage")
    opts.add_argument("--disable-gpu")
    opts.add_argument("--window-size=1280,900")
    opts.add_argument(
        "--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36"
    )

    driver = None
    try:
        driver = webdriver.Chrome(
            service=Service(ChromeDriverManager().install()),
            options=opts,
        )
        wait = WebDriverWait(driver, 20)

        logger.info(f"[RegoCheck/Selenium] Loading VicRoads page for {plate_text}...")
        driver.get(VICROADS_REGO_URL)
        time.sleep(3)

        # Fill in the car registration number field
        rego_input = wait.until(EC.presence_of_element_located((By.ID, "RegistrationNumbercar")))
        rego_input.clear()
        rego_input.send_keys(plate_text.upper())

        # Click the rego form submit button (not the login buttons)
        submit_btn = driver.find_element(By.CSS_SELECTOR, "input.mvc-form__actions-btn")
        driver.execute_script("arguments[0].click();", submit_btn)
        logger.info(f"[RegoCheck/Selenium] Form submitted, waiting for results...")
        time.sleep(6)

        raw_html = driver.page_source
        raw_hash = hashlib.sha256(raw_html.encode()).hexdigest()

        # Extract dl/dt/dd pairs — VicRoads result table format
        result: dict[str, str] = {}
        for dl in driver.find_elements(By.TAG_NAME, "dl"):
            dts = dl.find_elements(By.TAG_NAME, "dt")
            dds = dl.find_elements(By.TAG_NAME, "dd")
            for dt, dd in zip(dts, dds):
                key = dt.text.strip().lower()
                val = dd.text.strip()
                result[key] = val

        logger.info(f"[RegoCheck/Selenium] Raw result: {result}")
        result["_raw_hash"] = raw_hash
        return result if result else None

    except Exception as e:
        logger.error(f"[RegoCheck/Selenium] Error scraping {plate_text}: {e}", exc_info=True)
        return None
    finally:
        if driver:
            driver.quit()


async def _scrape_vicroads(plate_text: str, state_code: str) -> RegoResult | None:
    """
    Async wrapper — runs the synchronous Selenium scraper in a thread pool.
    """
    if state_code != "VIC":
        logger.info(f"[RegoCheck] Skipping non-VIC plate {state_code}·{plate_text}")
        return None

    await _rate_limit()

    loop = asyncio.get_event_loop()
    raw = await loop.run_in_executor(_executor, _selenium_scrape_sync, plate_text)

    if not raw:
        return None

    raw_hash = raw.pop("_raw_hash", "")

    # ── Parse: rego status & expiry ─────────────────────────────────────────
    status_raw = raw.get("registration status & expiry date", "")
    rego_status = "UNKNOWN"
    rego_expiry: datetime | None = None

    status_upper = status_raw.upper()
    if "CURRENT" in status_upper:
        rego_status = "CURRENT"
    elif "EXPIRED" in status_upper:
        rego_status = "EXPIRED"
    elif "CANCEL" in status_upper:
        rego_status = "CANCELLED"

    # Extract DD/MM/YYYY expiry date from e.g. "Current - 26/05/2026"
    date_match = re.search(r"(\d{2}/\d{2}/\d{4})", status_raw)
    if date_match:
        try:
            rego_expiry = datetime.strptime(date_match.group(1), "%d/%m/%Y").replace(
                tzinfo=timezone.utc
            )
        except ValueError:
            pass

    # ── Parse: vehicle details ───────────────────────────────────────────────
    year_text = raw.get("year", "")
    vehicle_year: int | None = None
    if year_text.isdigit():
        vehicle_year = int(year_text)

    vehicle_make  = raw.get("make") or None
    vehicle_model = raw.get("body type") or raw.get("model") or None
    vehicle_color = raw.get("colour") or raw.get("color") or None

    return RegoResult(
        state_code=state_code,
        plate_text=plate_text,
        rego_status=rego_status,
        vehicle_year=vehicle_year,
        vehicle_make=vehicle_make,
        vehicle_model=vehicle_model,
        vehicle_color=vehicle_color,
        rego_expiry_date=rego_expiry,
        raw_hash=raw_hash,
    )


async def enqueue_rego_check(
    plate_id: uuid.UUID,
    state_code: str,
    plate_text: str,
) -> None:
    """
    Background task called by FastAPI BackgroundTasks after plate creation / recheck.
    Fetches rego info via Selenium and updates the plate record in the database.
    """
    from backend.database import AsyncSessionLocal
    from backend.models.plate import Plate, RegoStatus

    logger.info(f"[RegoCheck] Starting check for {state_code}·{plate_text}")

    result = await _scrape_vicroads(plate_text, state_code)

    if result is None:
        logger.warning(f"[RegoCheck] No data for {state_code}·{plate_text} — marking UNKNOWN")
        result = RegoResult(
            state_code=state_code,
            plate_text=plate_text,
            rego_status="UNKNOWN",
            vehicle_year=None,
            vehicle_make=None,
            vehicle_model=None,
            vehicle_color=None,
            rego_expiry_date=None,
            raw_hash="",
        )

    async with AsyncSessionLocal() as db:
        plate = await db.get(Plate, plate_id)
        if not plate:
            logger.error(f"[RegoCheck] Plate {plate_id} not found in DB after check")
            return

        plate.rego_status      = RegoStatus(result.rego_status)
        plate.vehicle_year     = result.vehicle_year
        plate.vehicle_make     = result.vehicle_make
        plate.vehicle_model    = result.vehicle_model
        plate.vehicle_color    = result.vehicle_color
        plate.rego_expiry_date = result.rego_expiry_date
        plate.rego_checked_at  = datetime.now(timezone.utc)

        await db.commit()
        logger.info(
            f"[RegoCheck] ✓ {state_code}·{plate_text} → "
            f"{result.rego_status} | expires={result.rego_expiry_date} | "
            f"{result.vehicle_year} {result.vehicle_make} {result.vehicle_model} ({result.vehicle_color})"
        )