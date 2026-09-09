-- ========================================================
-- AMIA FEST - REGISTRATIONS SCHEMA ENHANCEMENT
-- Run this script in Supabase Dashboard -> SQL Editor
-- ========================================================

-- Ensure createdAt and created_at columns exist on public.registrations
ALTER TABLE public.registrations ADD COLUMN IF NOT EXISTS "createdAt" TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.registrations ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
