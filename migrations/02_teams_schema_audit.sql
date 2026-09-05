-- ========================================================
-- AMIA FEST - TEAMS SCHEMA AUDIT MIGRATION
-- Adds missing team columns and reloads PostgREST schema cache
-- ========================================================

ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "logo" TEXT;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "gradeA" INT DEFAULT 0;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "gradeB" INT DEFAULT 0;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "gradeC" INT DEFAULT 0;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "firstPlaces" INT DEFAULT 0;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "secondPlaces" INT DEFAULT 0;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "thirdPlaces" INT DEFAULT 0;

-- Force PostgREST schema cache refresh
NOTIFY pgrst, 'reload schema';
