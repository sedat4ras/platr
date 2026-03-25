-- Add device_token column for push notifications
ALTER TABLE users ADD COLUMN IF NOT EXISTS device_token VARCHAR(255);
