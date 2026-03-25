-- Custom plate system: remove icons, add custom_config, add VIC_BLACK style

ALTER TABLE plates DROP COLUMN IF EXISTS icon_left;
ALTER TABLE plates DROP COLUMN IF EXISTS icon_right;
ALTER TABLE plates ADD COLUMN IF NOT EXISTS custom_config TEXT;

-- Add VIC_BLACK to the enum
ALTER TYPE plate_style_enum ADD VALUE IF NOT EXISTS 'VIC_BLACK';
