-- Migration: Add new VIC plate styles to plate_style_enum
-- Run this against the platr database to add the new enum values.
--
-- New styles:
--   VIC_GARDEN_STATE  — Retro "Garden State" era plates
--   VIC_ON_THE_MOVE   — Retro "On the Move" era plates
--
-- Note: VIC_SLIMLINE_BLACK, VIC_DELUXE, VIC_PRESTIGE, VIC_EURO
--       were already added in a previous migration.

-- Add new enum values (IF NOT EXISTS prevents errors on re-run)
DO $$
BEGIN
    -- Check if VIC_GARDEN_STATE exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum
        WHERE enumlabel = 'VIC_GARDEN_STATE'
        AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'plate_style_enum')
    ) THEN
        ALTER TYPE plate_style_enum ADD VALUE 'VIC_GARDEN_STATE';
    END IF;

    -- Check if VIC_ON_THE_MOVE exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum
        WHERE enumlabel = 'VIC_ON_THE_MOVE'
        AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'plate_style_enum')
    ) THEN
        ALTER TYPE plate_style_enum ADD VALUE 'VIC_ON_THE_MOVE';
    END IF;
END $$;

-- Verify the enum values
SELECT enumlabel FROM pg_enum
WHERE enumtypid = (SELECT oid FROM pg_type WHERE typname = 'plate_style_enum')
ORDER BY enumsortorder;
