-- ========================================================
-- AMIA FEST - RESULTS SCHEMA ENHANCEMENT & SCHEMA CACHE FIX
-- Run this script in Supabase Dashboard -> SQL Editor
-- ========================================================

-- 1. Ensure both camelCase and snake_case columns exist on public.results
ALTER TABLE public.results ADD COLUMN IF NOT EXISTS "createdAt" TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.results ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE public.results ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.results ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE public.results ADD COLUMN IF NOT EXISTS "publishedAt" TIMESTAMPTZ;
ALTER TABLE public.results ADD COLUMN IF NOT EXISTS published_at TIMESTAMPTZ;

ALTER TABLE public.results ADD COLUMN IF NOT EXISTS "programId" TEXT;
ALTER TABLE public.results ADD COLUMN IF NOT EXISTS program_id TEXT;

ALTER TABLE public.results ADD COLUMN IF NOT EXISTS "studentId" TEXT;
ALTER TABLE public.results ADD COLUMN IF NOT EXISTS student_id TEXT;

ALTER TABLE public.results ADD COLUMN IF NOT EXISTS "teamId" TEXT;
ALTER TABLE public.results ADD COLUMN IF NOT EXISTS team_id TEXT;

ALTER TABLE public.results ADD COLUMN IF NOT EXISTS "juryId" TEXT;
ALTER TABLE public.results ADD COLUMN IF NOT EXISTS jury_id TEXT;

-- 2. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
