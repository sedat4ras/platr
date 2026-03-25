-- Plate system overhaul: ownership photo verification, visibility controls, space separator
ALTER TABLE plates ADD COLUMN IF NOT EXISTS has_space_separator BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE plates ADD COLUMN IF NOT EXISTS is_hidden BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE plates ADD COLUMN IF NOT EXISTS is_blocked_readd BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE plates ADD COLUMN IF NOT EXISTS ownership_photo_day1_path TEXT;
ALTER TABLE plates ADD COLUMN IF NOT EXISTS ownership_photo_day1_at TIMESTAMPTZ;
ALTER TABLE plates ADD COLUMN IF NOT EXISTS ownership_photo_day2_path TEXT;
ALTER TABLE plates ADD COLUMN IF NOT EXISTS ownership_photo_day2_at TIMESTAMPTZ;
ALTER TABLE plates ADD COLUMN IF NOT EXISTS ownership_verified BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE plates ADD COLUMN IF NOT EXISTS ownership_pending_user_id UUID REFERENCES users(id) ON DELETE SET NULL;
