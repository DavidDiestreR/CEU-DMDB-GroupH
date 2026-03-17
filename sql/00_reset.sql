\set ON_ERROR_STOP on
\pset pager off

-- ============================================================
-- 00_reset.sql
-- Safe reset for the project schema (DEV/TEST use).
--
-- This script is intentionally "public-ready":
--   - It does NOT drop the whole database.
--   - It only operates on a single schema (default: sandbox).
--
-- Usage (recommended):
--   1) Set variables in .env:
--      DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD, SCHEMA
--   2) Run the make target:
--      make reset-drop        # or: make reset-truncate / make reset-view
--
-- Modes:
--   mode=drop       : DROP project tables (and dependent objects)
--   mode=truncate   : TRUNCATE all known tables (clears data)
--   mode=reset-view : DROP project materialized views only
--
-- Notes:
--   - The schema is assumed to already exist.
--   - If you only have rights to modify data, use mode=truncate.
-- ============================================================

-- ---- Optional variables with defaults
\if :{?schema}
\else
  \set schema sandbox
\endif

\if :{?mode}
\else
  \set mode drop
\endif

\echo ''
\echo '== Reset config =='
\echo schema : :schema
\echo mode   : :mode
\echo ''

-- Evaluate mode in SQL (avoid psql expression parsing issues)
SELECT (:'mode' = 'drop')::int AS is_drop,
       (:'mode' = 'truncate')::int AS is_truncate,
       (:'mode' = 'reset-view')::int AS is_reset_view
\gset

-- ------------------------------------------------------------
-- mode = drop  (drop all project tables)
-- ------------------------------------------------------------
\if :is_drop
  \echo Dropping all project tables in schema :schema (CASCADE)...
  DROP MATERIALIZED VIEW IF EXISTS :"schema".student_timetable;
  DROP TABLE IF EXISTS
    :"schema".program_mandatory_elective_course,
    :"schema".program_elective_course,
    :"schema".program_mandatory_course,
    :"schema".course_has_hard_prerequisite_course,
    :"schema".department_instructor,
    :"schema".teaching_course,
    :"schema".student_passed_course,
    :"schema".student_enrolled_in_course,
    :"schema".student_requested_enrollment_in_course,
    :"schema".lesson,
    :"schema".class,
    :"schema".student,
    :"schema".course,
    :"schema".term,
    :"schema".program,
    :"schema".instructor,
    :"schema".department
  CASCADE;
  \echo Done. Tables dropped in schema :schema
  \quit
\endif

-- ------------------------------------------------------------
-- mode = truncate (clear data, keep tables)
-- ------------------------------------------------------------
\if :is_truncate
  \echo Truncating tables in schema :schema (CASCADE)...

  -- Order is not critical with CASCADE, but listing all project tables here
  -- makes the intent explicit.
  TRUNCATE TABLE
    :"schema".program_mandatory_elective_course,
    :"schema".program_elective_course,
    :"schema".program_mandatory_course,
    :"schema".course_has_hard_prerequisite_course,
    :"schema".department_instructor,
    :"schema".teaching_course,
    :"schema".student_passed_course,
    :"schema".student_enrolled_in_course,
    :"schema".student_requested_enrollment_in_course,
    :"schema".lesson,
    :"schema".class,
    :"schema".student,
    :"schema".course,
    :"schema".term,
    :"schema".program,
    :"schema".instructor,
    :"schema".department
  RESTART IDENTITY
  CASCADE;

  SELECT EXISTS (
    SELECT 1
    FROM pg_matviews
    WHERE schemaname = :'schema'
      AND matviewname = 'student_timetable'
  )::int AS has_student_timetable
  \gset

  \if :has_student_timetable
    REFRESH MATERIALIZED VIEW :"schema".student_timetable;
  \endif

  \echo Done. Data cleared in schema :schema
  \quit
\endif

-- ------------------------------------------------------------
-- mode = reset-view (drop project materialized views only)
-- ------------------------------------------------------------
\if :is_reset_view
  \echo Dropping project materialized views in schema :schema...
  DROP MATERIALIZED VIEW IF EXISTS :"schema".student_timetable;
  \echo Done. Materialized views dropped in schema :schema
  \quit
\endif

\echo ERROR: Unknown mode value. Use -v mode=drop, -v mode=truncate or -v mode=reset-view
\quit
