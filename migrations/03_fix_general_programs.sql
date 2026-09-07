-- ========================================================
-- AMIA FEST - FIX GENERAL PROGRAMS CATEGORIZATION
-- Run this script in Supabase Dashboard -> SQL Editor
-- ========================================================

-- Update incorrectly categorized programs to 'General' section 
-- and set isGeneral flag to true.
UPDATE public.programs 
SET 
  section = 'General', 
  "isGeneral" = true 
WHERE 
  UPPER(TRIM("programName")) IN (
    'INSTANT TABLOID MLM',
    'INSTANT TABLOID ARB',
    'INSTANT TABLOID ENG',
    'INSTANT TABLOID URD',
    'PODCAST MLM',
    'FEST BRANDING',
    'GROUP SONG',
    'MALAPPATU',
    'QASEEDA PARAYANAM',
    'QAWALI'
  )
  OR UPPER("programName") LIKE '%INSTANT%TABLOID%MLM%'
  OR UPPER("programName") LIKE '%INSTANT%TABLOID%ARB%'
  OR UPPER("programName") LIKE '%INSTANT%TABLOID%ENG%'
  OR UPPER("programName") LIKE '%INSTANT%TABLOID%URD%'
  OR UPPER("programName") LIKE '%PODCAST%MLM%'
  OR UPPER("programName") LIKE '%FEST%BRANDING%'
  OR UPPER("programName") LIKE '%GROUP%SONG%'
  OR UPPER("programName") LIKE '%MALAPPATU%'
  OR UPPER("programName") LIKE '%QASEEDA%PARAYANAM%'
  OR UPPER("programName") LIKE '%QAWALI%';
