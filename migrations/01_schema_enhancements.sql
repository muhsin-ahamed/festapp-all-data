-- ========================================================
-- AMIA FEST - DATABASE SCHEMA ENHANCEMENTS & MIGRATION
-- Run this script in Supabase Dashboard -> SQL Editor
-- ========================================================

-- 1. ENSURE ALL COLUMNS EXIST BEFORE RUNNING CONSTRAINTS OR UPDATES

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS "teamId" TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS "juryId" TEXT;

ALTER TABLE public.team_leaders ADD COLUMN IF NOT EXISTS "teamId" TEXT;

ALTER TABLE public.teams ADD COLUMN IF NOT EXISTS "leaderId" TEXT;

ALTER TABLE public.programs ADD COLUMN IF NOT EXISTS "venueId" TEXT;
ALTER TABLE public.programs ADD COLUMN IF NOT EXISTS "scheduleId" TEXT;

ALTER TABLE public.registrations ADD COLUMN IF NOT EXISTS "studentId" TEXT;
ALTER TABLE public.registrations ADD COLUMN IF NOT EXISTS "programId" TEXT;
ALTER TABLE public.registrations ADD COLUMN IF NOT EXISTS "teamId" TEXT;

ALTER TABLE public.results ADD COLUMN IF NOT EXISTS "programId" TEXT;
ALTER TABLE public.results ADD COLUMN IF NOT EXISTS "studentId" TEXT;
ALTER TABLE public.results ADD COLUMN IF NOT EXISTS "teamId" TEXT;
ALTER TABLE public.results ADD COLUMN IF NOT EXISTS "juryId" TEXT;

ALTER TABLE public.schedules ADD COLUMN IF NOT EXISTS "programId" TEXT;
ALTER TABLE public.schedules ADD COLUMN IF NOT EXISTS "venueId" TEXT;


-- 2. CLEANUP ORPHANED FOREIGN KEY REFERENCES IN EXISTING DATA

-- Clean orphaned teamId in users
UPDATE public.users
SET "teamId" = NULL
WHERE "teamId" IS NOT NULL
  AND "teamId" NOT IN (SELECT id FROM public.teams);

-- Clean orphaned juryId in users
UPDATE public.users
SET "juryId" = NULL
WHERE "juryId" IS NOT NULL
  AND "juryId" NOT IN (SELECT id FROM public.juries);

-- Clean orphaned teamId in team_leaders
UPDATE public.team_leaders
SET "teamId" = NULL
WHERE "teamId" IS NOT NULL
  AND "teamId" NOT IN (SELECT id FROM public.teams);

-- Clean orphaned leaderId in teams
UPDATE public.teams
SET "leaderId" = NULL
WHERE "leaderId" IS NOT NULL
  AND "leaderId" NOT IN (SELECT id FROM public.team_leaders);

-- Clean orphaned venueId & scheduleId in programs
UPDATE public.programs
SET "venueId" = NULL
WHERE "venueId" IS NOT NULL
  AND "venueId" NOT IN (SELECT id FROM public.venues);

UPDATE public.programs
SET "scheduleId" = NULL
WHERE "scheduleId" IS NOT NULL
  AND "scheduleId" NOT IN (SELECT id FROM public.schedules);

-- Clean orphaned registrations
DELETE FROM public.registrations
WHERE "studentId" NOT IN (SELECT id FROM public.students)
   OR "programId" NOT IN (SELECT id FROM public.programs)
   OR "teamId" NOT IN (SELECT id FROM public.teams);

-- Clean orphaned results
DELETE FROM public.results
WHERE "studentId" NOT IN (SELECT id FROM public.students)
   OR "programId" NOT IN (SELECT id FROM public.programs)
   OR "teamId" NOT IN (SELECT id FROM public.teams);

UPDATE public.results
SET "juryId" = NULL
WHERE "juryId" IS NOT NULL
  AND "juryId" NOT IN (SELECT id FROM public.juries);

-- Clean orphaned schedules
DELETE FROM public.schedules
WHERE "programId" NOT IN (SELECT id FROM public.programs)
   OR "venueId" NOT IN (SELECT id FROM public.venues);

-- Remove duplicate registrations if any exist before adding unique constraint
DELETE FROM public.registrations a USING public.registrations b
WHERE a.ctid < b.ctid
  AND a."studentId" = b."studentId"
  AND a."programId" = b."programId";


-- 3. SAFE FOREIGN KEY & COMPOSITE CONSTRAINTS

ALTER TABLE public.users DROP CONSTRAINT IF EXISTS fk_users_team;
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS fk_users_jury;
ALTER TABLE public.users
  ADD CONSTRAINT fk_users_team FOREIGN KEY ("teamId") REFERENCES public.teams(id) ON DELETE SET NULL,
  ADD CONSTRAINT fk_users_jury FOREIGN KEY ("juryId") REFERENCES public.juries(id) ON DELETE SET NULL;

ALTER TABLE public.students DROP CONSTRAINT IF EXISTS fk_students_team;
ALTER TABLE public.students
  ADD CONSTRAINT fk_students_team FOREIGN KEY ("teamId") REFERENCES public.teams(id) ON DELETE CASCADE;

ALTER TABLE public.team_leaders DROP CONSTRAINT IF EXISTS fk_team_leaders_team;
ALTER TABLE public.team_leaders
  ADD CONSTRAINT fk_team_leaders_team FOREIGN KEY ("teamId") REFERENCES public.teams(id) ON DELETE SET NULL;

ALTER TABLE public.teams DROP CONSTRAINT IF EXISTS fk_teams_leader;
ALTER TABLE public.teams
  ADD CONSTRAINT fk_teams_leader FOREIGN KEY ("leaderId") REFERENCES public.team_leaders(id) ON DELETE SET NULL;

ALTER TABLE public.programs DROP CONSTRAINT IF EXISTS fk_programs_venue;
ALTER TABLE public.programs DROP CONSTRAINT IF EXISTS fk_programs_schedule;
ALTER TABLE public.programs
  ADD CONSTRAINT fk_programs_venue FOREIGN KEY ("venueId") REFERENCES public.venues(id) ON DELETE SET NULL,
  ADD CONSTRAINT fk_programs_schedule FOREIGN KEY ("scheduleId") REFERENCES public.schedules(id) ON DELETE SET NULL;

ALTER TABLE public.registrations DROP CONSTRAINT IF EXISTS fk_registrations_student;
ALTER TABLE public.registrations DROP CONSTRAINT IF EXISTS fk_registrations_program;
ALTER TABLE public.registrations DROP CONSTRAINT IF EXISTS fk_registrations_team;
ALTER TABLE public.registrations DROP CONSTRAINT IF EXISTS unique_student_program;
ALTER TABLE public.registrations
  ADD CONSTRAINT fk_registrations_student FOREIGN KEY ("studentId") REFERENCES public.students(id) ON DELETE CASCADE,
  ADD CONSTRAINT fk_registrations_program FOREIGN KEY ("programId") REFERENCES public.programs(id) ON DELETE CASCADE,
  ADD CONSTRAINT fk_registrations_team FOREIGN KEY ("teamId") REFERENCES public.teams(id) ON DELETE CASCADE,
  ADD CONSTRAINT unique_student_program UNIQUE ("studentId", "programId");

ALTER TABLE public.results DROP CONSTRAINT IF EXISTS fk_results_program;
ALTER TABLE public.results DROP CONSTRAINT IF EXISTS fk_results_student;
ALTER TABLE public.results DROP CONSTRAINT IF EXISTS fk_results_team;
ALTER TABLE public.results DROP CONSTRAINT IF EXISTS fk_results_jury;
ALTER TABLE public.results
  ADD CONSTRAINT fk_results_program FOREIGN KEY ("programId") REFERENCES public.programs(id) ON DELETE CASCADE,
  ADD CONSTRAINT fk_results_student FOREIGN KEY ("studentId") REFERENCES public.students(id) ON DELETE CASCADE,
  ADD CONSTRAINT fk_results_team FOREIGN KEY ("teamId") REFERENCES public.teams(id) ON DELETE CASCADE,
  ADD CONSTRAINT fk_results_jury FOREIGN KEY ("juryId") REFERENCES public.juries(id) ON DELETE SET NULL;

ALTER TABLE public.schedules DROP CONSTRAINT IF EXISTS fk_schedules_program;
ALTER TABLE public.schedules DROP CONSTRAINT IF EXISTS fk_schedules_venue;
ALTER TABLE public.schedules
  ADD CONSTRAINT fk_schedules_program FOREIGN KEY ("programId") REFERENCES public.programs(id) ON DELETE CASCADE,
  ADD CONSTRAINT fk_schedules_venue FOREIGN KEY ("venueId") REFERENCES public.venues(id) ON DELETE CASCADE;


-- 4. JURY PROGRAM ASSIGNMENTS TABLE
CREATE TABLE IF NOT EXISTS public.jury_program_assignments (
  id TEXT PRIMARY KEY,
  "juryId" TEXT NOT NULL REFERENCES public.juries(id) ON DELETE CASCADE,
  "programId" TEXT NOT NULL REFERENCES public.programs(id) ON DELETE CASCADE,
  "createdAt" TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_jury_program UNIQUE ("juryId", "programId")
);


-- 5. INDEXES FOR HIGH FREQUENCY QUERIES
CREATE INDEX IF NOT EXISTS idx_students_team_id ON public.students("teamId");
CREATE INDEX IF NOT EXISTS idx_students_section ON public.students("section");
CREATE INDEX IF NOT EXISTS idx_students_chase ON public.students("chaseNumber");

CREATE INDEX IF NOT EXISTS idx_programs_section ON public.programs("section");
CREATE INDEX IF NOT EXISTS idx_programs_category ON public.programs("category");

CREATE INDEX IF NOT EXISTS idx_registrations_student ON public.registrations("studentId");
CREATE INDEX IF NOT EXISTS idx_registrations_program ON public.registrations("programId");
CREATE INDEX IF NOT EXISTS idx_registrations_team ON public.registrations("teamId");

CREATE INDEX IF NOT EXISTS idx_results_program ON public.results("programId");
CREATE INDEX IF NOT EXISTS idx_results_student ON public.results("studentId");
CREATE INDEX IF NOT EXISTS idx_results_team ON public.results("teamId");
CREATE INDEX IF NOT EXISTS idx_results_status ON public.results("status");

CREATE INDEX IF NOT EXISTS idx_jury_assignments_jury ON public.jury_program_assignments("juryId");
CREATE INDEX IF NOT EXISTS idx_jury_assignments_program ON public.jury_program_assignments("programId");
