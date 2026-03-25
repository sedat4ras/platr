-- Migration: Add apple_id and date_of_birth columns to users table
-- Required for: Sign in with Apple + Age verification (App Store compliance)
-- Run: psql -U platr -d platr -f backend/migrations/add_apple_id_and_dob.sql

ALTER TABLE users ADD COLUMN IF NOT EXISTS apple_id VARCHAR(255) UNIQUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS date_of_birth TIMESTAMPTZ;

CREATE UNIQUE INDEX IF NOT EXISTS ix_users_apple_id ON users (apple_id) WHERE apple_id IS NOT NULL;
