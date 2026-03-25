-- Star system overhaul: remove spot/location, add stars, VicRoads ownership, plate photo

-- Remove location fields (no longer tracking plate locations)
ALTER TABLE plates DROP COLUMN IF EXISTS latitude;
ALTER TABLE plates DROP COLUMN IF EXISTS longitude;

-- Replace spot_count with star_count
ALTER TABLE plates DROP COLUMN IF EXISTS spot_count;
ALTER TABLE plates ADD COLUMN IF NOT EXISTS star_count INTEGER NOT NULL DEFAULT 0;

-- Plate photo (owner can upload their real plate photo)
ALTER TABLE plates ADD COLUMN IF NOT EXISTS plate_photo_path TEXT;

-- VicRoads screenshot ownership verification
ALTER TABLE plates ADD COLUMN IF NOT EXISTS vicroads_screenshot_path TEXT;
ALTER TABLE plates ADD COLUMN IF NOT EXISTS vicroads_screenshot_at TIMESTAMPTZ;

-- Add new VIC plate style enum values
ALTER TYPE plate_style_enum ADD VALUE IF NOT EXISTS 'VIC_GARDEN_STATE';
ALTER TYPE plate_style_enum ADD VALUE IF NOT EXISTS 'VIC_ON_THE_MOVE';
ALTER TYPE plate_style_enum ADD VALUE IF NOT EXISTS 'VIC_CUSTOM';

-- PlateStarring table (one row per user per plate)
CREATE TABLE IF NOT EXISTS plate_starring (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plate_id UUID NOT NULL REFERENCES plates(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_starring_plate_user UNIQUE (plate_id, user_id)
);

CREATE INDEX IF NOT EXISTS ix_plate_starring_plate_id ON plate_starring(plate_id);
CREATE INDEX IF NOT EXISTS ix_plate_starring_user_id ON plate_starring(user_id);
