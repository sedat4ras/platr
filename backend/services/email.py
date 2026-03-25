"""
Platr Backend — Email Service
Sends transactional emails via Gmail SMTP using aiosmtplib.
"""

from __future__ import annotations

import logging
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

import aiosmtplib

from backend.config import settings

logger = logging.getLogger(__name__)

_GMAIL_HOST = "smtp.gmail.com"
_GMAIL_PORT = 587


async def send_verification_email(to_email: str, code: str) -> None:
    """Send a 6-digit verification code to the user's email address."""
    if not settings.gmail_user or not settings.gmail_app_password:
        logger.warning("Gmail not configured — skipping email send (code: %s)", code)
        return

    msg = MIMEMultipart("alternative")
    msg["Subject"] = f"{code} — Platr Email Verification"
    msg["From"] = f"Platr <{settings.gmail_user}>"
    msg["To"] = to_email

    html = f"""\
<html>
  <body style="font-family: -apple-system, sans-serif; background: #f5f5f5; padding: 32px;">
    <div style="max-width: 400px; margin: 0 auto; background: #fff;
                border-radius: 16px; padding: 32px; text-align: center;">
      <p style="font-size: 40px; margin: 0;">🚘</p>
      <h1 style="font-size: 28px; font-weight: 900; margin: 8px 0 4px;">Platr</h1>
      <p style="color: #888; margin: 0 0 28px;">Spot &amp; share number plates</p>

      <p style="color: #333; margin-bottom: 16px;">
        Enter this code to verify your email address:
      </p>

      <div style="font-size: 42px; font-weight: 900; letter-spacing: 12px;
                  background: #f0f4ff; border-radius: 12px; padding: 20px;">
        {code}
      </div>

      <p style="color: #999; font-size: 13px; margin-top: 24px;">
        This code expires in <strong>15 minutes</strong>.<br>
        If you didn't create a Platr account, you can ignore this email.
      </p>
    </div>
  </body>
</html>
"""
    plain = f"Your Platr verification code is: {code}\n\nThis code expires in 15 minutes."

    msg.attach(MIMEText(plain, "plain"))
    msg.attach(MIMEText(html, "html"))

    try:
        await aiosmtplib.send(
            msg,
            hostname=_GMAIL_HOST,
            port=_GMAIL_PORT,
            username=settings.gmail_user,
            password=settings.gmail_app_password,
            start_tls=True,
        )
        logger.info("Verification email sent to %s", to_email)
    except Exception as exc:
        logger.error("Failed to send verification email to %s: %s", to_email, exc)
        # Don't re-raise — email failure shouldn't block registration


async def send_admin_moderation_alert(
    trigger: str,
    comment_id: str,
    plate_text: str,
    author_username: str,
    comment_body: str,
    reason: str,
) -> None:
    """
    Send moderation alert to admin email.
    Triggered by: keyword filter hit OR user report.
    """
    if not settings.gmail_user or not settings.gmail_app_password:
        logger.warning("[Admin Alert] Gmail not configured — skipping alert")
        return

    subject = f"[Platr Moderation] {trigger} — {plate_text}"
    admin_email = getattr(settings, "admin_email", settings.gmail_user)

    html = f"""\
<html>
  <body style="font-family: -apple-system, sans-serif; background: #f5f5f5; padding: 32px;">
    <div style="max-width: 500px; margin: 0 auto; background: #fff;
                border-radius: 16px; padding: 32px;">
      <h1 style="font-size: 20px; font-weight: 900; color: #e53e3e; margin: 0 0 16px;">
        Platr Moderation Alert
      </h1>
      <table style="width: 100%; border-collapse: collapse; font-size: 14px;">
        <tr><td style="padding: 6px 0; color: #888;">Trigger</td>
            <td style="padding: 6px 0; font-weight: 600;">{trigger}</td></tr>
        <tr><td style="padding: 6px 0; color: #888;">Plate</td>
            <td style="padding: 6px 0;">{plate_text}</td></tr>
        <tr><td style="padding: 6px 0; color: #888;">Author</td>
            <td style="padding: 6px 0;">@{author_username}</td></tr>
        <tr><td style="padding: 6px 0; color: #888;">Reason</td>
            <td style="padding: 6px 0; color: #e53e3e;">{reason}</td></tr>
        <tr><td style="padding: 6px 0; color: #888;">Comment ID</td>
            <td style="padding: 6px 0; font-family: monospace; font-size: 12px;">{comment_id}</td></tr>
      </table>
      <div style="background: #f8f8f8; border-radius: 8px; padding: 16px; margin-top: 16px;
                  border-left: 4px solid #e53e3e;">
        <p style="margin: 0; color: #333; font-style: italic;">"{comment_body}"</p>
      </div>
    </div>
  </body>
</html>
"""

    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = f"Platr <{settings.gmail_user}>"
    msg["To"] = admin_email
    msg.attach(MIMEText(f"[{trigger}] @{author_username} on {plate_text}\n\n{comment_body}\n\nReason: {reason}\nComment ID: {comment_id}", "plain"))
    msg.attach(MIMEText(html, "html"))

    try:
        await aiosmtplib.send(
            msg,
            hostname=_GMAIL_HOST,
            port=_GMAIL_PORT,
            username=settings.gmail_user,
            password=settings.gmail_app_password,
            start_tls=True,
        )
        logger.info("[Admin Alert] Sent to %s — %s", admin_email, subject)
    except Exception as exc:
        logger.error("[Admin Alert] Failed to send: %s", exc)


async def send_password_reset_email(to_email: str, code: str) -> None:
    """Send a 6-digit password reset code to the user's email address."""
    if not settings.gmail_user or not settings.gmail_app_password:
        logger.warning("Gmail not configured — skipping password reset email (code: %s)", code)
        return

    msg = MIMEMultipart("alternative")
    msg["Subject"] = f"{code} — Platr Password Reset"
    msg["From"] = f"Platr <{settings.gmail_user}>"
    msg["To"] = to_email

    html = f"""\
<html>
  <body style="font-family: -apple-system, sans-serif; background: #f5f5f5; padding: 32px;">
    <div style="max-width: 400px; margin: 0 auto; background: #fff;
                border-radius: 16px; padding: 32px; text-align: center;">
      <p style="font-size: 40px; margin: 0;">&#x1F512;</p>
      <h1 style="font-size: 28px; font-weight: 900; margin: 8px 0 4px;">Platr</h1>
      <p style="color: #888; margin: 0 0 28px;">Password Reset</p>

      <p style="color: #333; margin-bottom: 16px;">
        Enter this code to reset your password:
      </p>

      <div style="font-size: 42px; font-weight: 900; letter-spacing: 12px;
                  background: #fff0f0; border-radius: 12px; padding: 20px;">
        {code}
      </div>

      <p style="color: #999; font-size: 13px; margin-top: 24px;">
        This code expires in <strong>15 minutes</strong>.<br>
        If you didn't request a password reset, you can ignore this email.
      </p>
    </div>
  </body>
</html>
"""
    plain = f"Your Platr password reset code is: {code}\\n\\nThis code expires in 15 minutes."

    msg.attach(MIMEText(plain, "plain"))
    msg.attach(MIMEText(html, "html"))

    try:
        await aiosmtplib.send(
            msg,
            hostname=_GMAIL_HOST,
            port=_GMAIL_PORT,
            username=settings.gmail_user,
            password=settings.gmail_app_password,
            start_tls=True,
        )
        logger.info("Password reset email sent to %s", to_email)
    except Exception as exc:
        logger.error("Failed to send password reset email to %s: %s", to_email, exc)
