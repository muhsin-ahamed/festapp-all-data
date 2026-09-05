-- ========================================================
-- AMIA FEST - SUPABASE DATABASE SCHEMA (COMPLETE & ACCURATE)
-- Run this script in Supabase Dashboard -> SQL Editor
-- ========================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. USERS TABLE
CREATE TABLE IF NOT EXISTS public.users (
  id TEXT PRIMARY KEY,
  auth_user_id UUID,
  username TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  role TEXT NOT NULL,
  team_id TEXT,
  "teamId" TEXT,
  jury_id TEXT,
  "juryId" TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  "createdAt" TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Migration helpers for users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS auth_user_id UUID;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS team_id TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS jury_id TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.users DROP COLUMN IF EXISTS password;

-- Seed default quick login profiles (Passwords are managed securely via Supabase Auth)
INSERT INTO public.users (id, username, name, role, team_id, "teamId", is_active)
VALUES 
  ('usr_controller', 'ksams', 'Fest Controller (KSAMS)', 'FEST_CONTROLLER', NULL, NULL, true),
  ('usr_tv', 'tv', 'TV Display Operator', 'TV_OPERATOR', NULL, NULL, true),
  ('usr_jury1', 'jury1', 'Jury Member 1', 'JURY', NULL, NULL, true),
  ('usr_leader1', 'lsmht', 'SHAHIL K (Apex)', 'TEAM_LEADER', 'team_01', 'team_01', true),
  ('usr_leader2', 'halans', 'ALTHAF HUSSAIN (Telos)', 'TEAM_LEADER', 'team_02', 'team_02', true)
ON CONFLICT (id) DO UPDATE SET
  username = EXCLUDED.username,
  name = EXCLUDED.name,
  role = EXCLUDED.role,
  team_id = EXCLUDED.team_id,
  "teamId" = EXCLUDED."teamId",
  is_active = EXCLUDED.is_active;

-- 2. STUDENTS TABLE
CREATE TABLE IF NOT EXISTS public.students (
  id TEXT PRIMARY KEY,
  "chaseNumber" TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  gender TEXT NOT NULL,
  "dateOfBirth" TEXT,
  section TEXT NOT NULL,
  "teamId" TEXT NOT NULL,
  phone TEXT,
  "className" TEXT,
  "schoolName" TEXT,
  photo TEXT,
  "qrCode" TEXT,
  "createdAt" TIMESTAMPTZ DEFAULT NOW(),
  "updatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TEAMS TABLE
CREATE TABLE IF NOT EXISTS public.teams (
  id TEXT PRIMARY KEY,
  "teamName" TEXT NOT NULL,
  "teamCode" TEXT UNIQUE NOT NULL,
  "leaderId" TEXT,
  "leaderName" TEXT,
  "mentorName" TEXT,
  "assistantLeaderName" TEXT,
  section TEXT,
  logo TEXT,
  "totalStudents" INT DEFAULT 0,
  "totalPoints" INT DEFAULT 0,
  rank INT DEFAULT 0,
  "gradeA" INT DEFAULT 0,
  "gradeB" INT DEFAULT 0,
  "gradeC" INT DEFAULT 0,
  "firstPlaces" INT DEFAULT 0,
  "secondPlaces" INT DEFAULT 0,
  "thirdPlaces" INT DEFAULT 0,
  status TEXT DEFAULT 'ACTIVE',
  "createdAt" TIMESTAMPTZ DEFAULT NOW(),
  "updatedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TEAM LEADERS TABLE
CREATE TABLE IF NOT EXISTS public.team_leaders (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  "teamId" TEXT,
  status TEXT DEFAULT 'ACTIVE'
);

-- 5. PROGRAMS TABLE
CREATE TABLE IF NOT EXISTS public.programs (
  id TEXT PRIMARY KEY,
  "programCode" TEXT UNIQUE NOT NULL,
  "programName" TEXT NOT NULL,
  section TEXT NOT NULL,
  category TEXT NOT NULL,
  "isStageProgram" BOOLEAN DEFAULT true,
  "isGeneral" BOOLEAN DEFAULT false,
  "maxParticipants" INT DEFAULT 1,
  duration TEXT,
  "venueId" TEXT,
  "scheduleId" TEXT,
  rules TEXT,
  status TEXT DEFAULT 'UPCOMING'
);

-- 6. REGISTRATIONS TABLE
CREATE TABLE IF NOT EXISTS public.registrations (
  id TEXT PRIMARY KEY,
  "studentId" TEXT NOT NULL,
  "programId" TEXT NOT NULL,
  "teamId" TEXT NOT NULL,
  "registrationNumber" TEXT UNIQUE NOT NULL,
  status TEXT NOT NULL,
  "createdAt" TIMESTAMPTZ DEFAULT NOW()
);

-- 7. RESULTS TABLE
CREATE TABLE IF NOT EXISTS public.results (
  id TEXT PRIMARY KEY,
  "programId" TEXT NOT NULL,
  "studentId" TEXT NOT NULL,
  "teamId" TEXT NOT NULL,
  "juryId" TEXT,
  marks NUMERIC DEFAULT 0,
  grade TEXT,
  position INT,
  points INT DEFAULT 0,
  remarks TEXT,
  status TEXT NOT NULL,
  "createdAt" TIMESTAMPTZ DEFAULT NOW(),
  "updatedAt" TIMESTAMPTZ DEFAULT NOW(),
  "publishedAt" TIMESTAMPTZ
);

-- 8. VENUES TABLE
CREATE TABLE IF NOT EXISTS public.venues (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  location TEXT,
  capacity INT DEFAULT 100,
  description TEXT
);

-- 9. SCHEDULES TABLE
CREATE TABLE IF NOT EXISTS public.schedules (
  id TEXT PRIMARY KEY,
  "programId" TEXT NOT NULL,
  "venueId" TEXT NOT NULL,
  date TEXT,
  "startTime" TEXT,
  "endTime" TEXT,
  status TEXT DEFAULT 'SCHEDULED'
);

-- 10. JURIES TABLE
CREATE TABLE IF NOT EXISTS public.juries (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  "juryCode" TEXT UNIQUE NOT NULL,
  "assignedPrograms" JSONB DEFAULT '[]'::jsonb,
  status TEXT DEFAULT 'ACTIVE'
);

-- 11. ANNOUNCEMENTS TABLE
CREATE TABLE IF NOT EXISTS public.announcements (
  id TEXT PRIMARY KEY,
  "programId" TEXT,
  "resultId" TEXT,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  status TEXT DEFAULT 'ANNOUNCED',
  "createdAt" TIMESTAMPTZ DEFAULT NOW(),
  "announcedAt" TIMESTAMPTZ DEFAULT NOW()
);

-- 12. TV SETTINGS TABLE
CREATE TABLE IF NOT EXISTS public.tv_settings (
  id TEXT PRIMARY KEY DEFAULT 'default',
  "scrollSpeed" INT DEFAULT 30,
  "autoRefreshSeconds" INT DEFAULT 10,
  theme TEXT DEFAULT 'dark',
  "showTopTeamsCount" INT DEFAULT 5,
  "activeAnnouncementId" TEXT
);

-- 13. AUDIT LOGS TABLE
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id TEXT PRIMARY KEY,
  action TEXT NOT NULL,
  details TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  "performedBy" TEXT
);

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_leaders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.venues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.juries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tv_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Drop all existing policy variations
DROP POLICY IF EXISTS "Public Read/Write Users" ON public.users CASCADE;
DROP POLICY IF EXISTS "users_public_access" ON public.users CASCADE;

DROP POLICY IF EXISTS "Public Read/Write Students" ON public.students CASCADE;
DROP POLICY IF EXISTS "students_public_access" ON public.students CASCADE;

DROP POLICY IF EXISTS "Public Read/Write Teams" ON public.teams CASCADE;
DROP POLICY IF EXISTS "teams_public_access" ON public.teams CASCADE;

DROP POLICY IF EXISTS "Public Read/Write Team Leaders" ON public.team_leaders CASCADE;
DROP POLICY IF EXISTS "team_leaders_public_access" ON public.team_leaders CASCADE;

DROP POLICY IF EXISTS "Public Read/Write Programs" ON public.programs CASCADE;
DROP POLICY IF EXISTS "programs_public_access" ON public.programs CASCADE;

DROP POLICY IF EXISTS "Public Read/Write Registrations" ON public.registrations CASCADE;
DROP POLICY IF EXISTS "registrations_public_access" ON public.registrations CASCADE;

DROP POLICY IF EXISTS "Public Read/Write Results" ON public.results CASCADE;
DROP POLICY IF EXISTS "results_public_access" ON public.results CASCADE;

DROP POLICY IF EXISTS "Public Read/Write Venues" ON public.venues CASCADE;
DROP POLICY IF EXISTS "venues_public_access" ON public.venues CASCADE;

DROP POLICY IF EXISTS "Public Read/Write Schedules" ON public.schedules CASCADE;
DROP POLICY IF EXISTS "schedules_public_access" ON public.schedules CASCADE;

DROP POLICY IF EXISTS "Public Read/Write Juries" ON public.juries CASCADE;
DROP POLICY IF EXISTS "juries_public_access" ON public.juries CASCADE;

DROP POLICY IF EXISTS "Public Read/Write Announcements" ON public.announcements CASCADE;
DROP POLICY IF EXISTS "announcements_public_access" ON public.announcements CASCADE;

DROP POLICY IF EXISTS "Public Read/Write TV Settings" ON public.tv_settings CASCADE;
DROP POLICY IF EXISTS "tv_settings_public_access" ON public.tv_settings CASCADE;

DROP POLICY IF EXISTS "Public Read/Write Audit Logs" ON public.audit_logs CASCADE;
DROP POLICY IF EXISTS "audit_logs_public_access" ON public.audit_logs CASCADE;

-- Create clean public access policies
CREATE POLICY "users_public_access" ON public.users FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "students_public_access" ON public.students FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "teams_public_access" ON public.teams FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "team_leaders_public_access" ON public.team_leaders FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "programs_public_access" ON public.programs FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "registrations_public_access" ON public.registrations FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "results_public_access" ON public.results FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "venues_public_access" ON public.venues FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "schedules_public_access" ON public.schedules FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "juries_public_access" ON public.juries FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "announcements_public_access" ON public.announcements FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "tv_settings_public_access" ON public.tv_settings FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "audit_logs_public_access" ON public.audit_logs FOR ALL USING (true) WITH CHECK (true);

-- Migration helpers for existing tables:
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "createdAt" TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "assistantLeaderName" TEXT;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "mentorName" TEXT;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "leaderName" TEXT;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "leaderId" TEXT;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "section" TEXT;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "logo" TEXT;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "totalStudents" INT DEFAULT 0;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "totalPoints" INT DEFAULT 0;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "rank" INT DEFAULT 0;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "gradeA" INT DEFAULT 0;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "gradeB" INT DEFAULT 0;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "gradeC" INT DEFAULT 0;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "firstPlaces" INT DEFAULT 0;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "secondPlaces" INT DEFAULT 0;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "thirdPlaces" INT DEFAULT 0;
ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "status" TEXT DEFAULT 'ACTIVE';

ALTER TABLE public.team_leaders ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'ACTIVE';

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS "teamId" TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS "juryId" TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS "createdAt" TIMESTAMPTZ DEFAULT NOW();

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
