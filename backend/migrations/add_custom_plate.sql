-- Add VIC_CUSTOM plate style and custom_bg_color column
-- Run: psql -U platr -d platr -f backend/migrations/add_custom_plate.sql

ALTER TYPE plate_style_enum ADD VALUE IF NOT EXISTS 'VIC_CUSTOM';

ALTER TABLE plates ADD COLUMN IF NOT EXISTS custom_bg_color VARCHAR(7);
