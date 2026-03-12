-- ============================================================
-- 04_load_from_dir.sql
-- Simple CSV loader - loads from hardcoded data directory
--
-- Usage (recommended):
--   1) Set variables in .env:
--      DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD, SCHEMA
--   2) Run the make target:
--      make load              # or: make load-truncate
--
-- Notes:
--   - This version uses hardcoded paths and schema names.
--   - It expects CSVs in data/dump_folder/ with specific names matching the tables.
--   - This script supports both Windows and macOS/Linux file checks.
-- ============================================================

\pset pager off
\set ON_ERROR_STOP off
\if :{?schema}
\else
  \set schema sandbox
\endif

-- Schema is assumed to exist (no CREATE privilege).
SET search_path TO :"schema";

\if :{?is_windows}
\else
  \set is_windows false
\endif

\echo
\echo '== Loading CSV files =='
\echo

\if :is_windows
  \set has_department `powershell -NoProfile -Command "if (Test-Path 'data\\dump_folder\\department.csv') { 'true' } else { 'false' }"`
\else
  \set has_department `sh -c "if [ -f 'data/dump_folder/department.csv' ]; then echo true; else echo false; fi"`
\endif
\if :has_department
  \echo 'Loading department...'
  \copy department FROM 'data/dump_folder/department.csv' WITH (FORMAT csv, HEADER true)
\endif

\if :is_windows
  \set has_instructor `powershell -NoProfile -Command "if (Test-Path 'data\\dump_folder\\instructor.csv') { 'true' } else { 'false' }"`
\else
  \set has_instructor `sh -c "if [ -f 'data/dump_folder/instructor.csv' ]; then echo true; else echo false; fi"`
\endif
\if :has_instructor
  \echo 'Loading instructor...'
  \copy instructor FROM 'data/dump_folder/instructor.csv' WITH (FORMAT csv, HEADER true)
\endif

\if :is_windows
  \set has_program `powershell -NoProfile -Command "if (Test-Path 'data\\dump_folder\\program.csv') { 'true' } else { 'false' }"`
\else
  \set has_program `sh -c "if [ -f 'data/dump_folder/program.csv' ]; then echo true; else echo false; fi"`
\endif
\if :has_program
  \echo 'Loading program...'
  \copy program FROM 'data/dump_folder/program.csv' WITH (FORMAT csv, HEADER true)
\endif

\if :is_windows
  \set has_term `powershell -NoProfile -Command "if (Test-Path 'data\\dump_folder\\term.csv') { 'true' } else { 'false' }"`
\else
  \set has_term `sh -c "if [ -f 'data/dump_folder/term.csv' ]; then echo true; else echo false; fi"`
\endif
\if :has_term
  \echo 'Loading term...'
  \copy term FROM 'data/dump_folder/term.csv' WITH (FORMAT csv, HEADER true)
\endif

\if :is_windows
  \set has_course `powershell -NoProfile -Command "if (Test-Path 'data\\dump_folder\\course.csv') { 'true' } else { 'false' }"`
\else
  \set has_course `sh -c "if [ -f 'data/dump_folder/course.csv' ]; then echo true; else echo false; fi"`
\endif
\if :has_course
  \echo 'Loading course...'
  \copy course FROM 'data/dump_folder/course.csv' WITH (FORMAT csv, HEADER true)
\endif

\if :is_windows
  \set has_course_has_hard_prerequisite_course `powershell -NoProfile -Command "if (Test-Path 'data\\dump_folder\\course_has_hard_prerequisite_course.csv') { 'true' } else { 'false' }"`
\else
  \set has_course_has_hard_prerequisite_course `sh -c "if [ -f 'data/dump_folder/course_has_hard_prerequisite_course.csv' ]; then echo true; else echo false; fi"`
\endif
\if :has_course_has_hard_prerequisite_course
  \echo 'Loading course_has_hard_prerequisite_course...'
  \copy course_has_hard_prerequisite_course FROM 'data/dump_folder/course_has_hard_prerequisite_course.csv' WITH (FORMAT csv, HEADER true)
\endif

\if :is_windows
  \set has_student `powershell -NoProfile -Command "if (Test-Path 'data\\dump_folder\\student.csv') { 'true' } else { 'false' }"`
\else
  \set has_student `sh -c "if [ -f 'data/dump_folder/student.csv' ]; then echo true; else echo false; fi"`
\endif
\if :has_student
  \echo 'Loading student...'
  \copy student FROM 'data/dump_folder/student.csv' WITH (FORMAT csv, HEADER true)
\endif

\if :is_windows
  \set has_class `powershell -NoProfile -Command "if (Test-Path 'data\\dump_folder\\class.csv') { 'true' } else { 'false' }"`
\else
  \set has_class `sh -c "if [ -f 'data/dump_folder/class.csv' ]; then echo true; else echo false; fi"`
\endif
\if :has_class
  \echo 'Loading class...'
  \copy class FROM 'data/dump_folder/class.csv' WITH (FORMAT csv, HEADER true)
\endif



\if :is_windows
  \set has_department_instructor `powershell -NoProfile -Command "if (Test-Path 'data\\dump_folder\\department_instructor.csv') { 'true' } else { 'false' }"`
\else
  \set has_department_instructor `sh -c "if [ -f 'data/dump_folder/department_instructor.csv' ]; then echo true; else echo false; fi"`
\endif
\if :has_department_instructor
  \echo 'Loading department_instructor...'
  \copy department_instructor FROM 'data/dump_folder/department_instructor.csv' WITH (FORMAT csv, HEADER true)
\endif

\if :is_windows
  \set has_teaching_course `powershell -NoProfile -Command "if (Test-Path 'data\\dump_folder\\teaching_course.csv') { 'true' } else { 'false' }"`
\else
  \set has_teaching_course `sh -c "if [ -f 'data/dump_folder/teaching_course.csv' ]; then echo true; else echo false; fi"`
\endif
\if :has_teaching_course
  \echo 'Loading teaching_course...'
  \copy teaching_course FROM 'data/dump_folder/teaching_course.csv' WITH (FORMAT csv, HEADER true)
\endif

\if :is_windows
  \set has_program_mandatory_course `powershell -NoProfile -Command "if (Test-Path 'data\\dump_folder\\program_mandatory_course.csv') { 'true' } else { 'false' }"`
\else
  \set has_program_mandatory_course `sh -c "if [ -f 'data/dump_folder/program_mandatory_course.csv' ]; then echo true; else echo false; fi"`
\endif
\if :has_program_mandatory_course
  \echo 'Loading program_mandatory_course...'
  \copy program_mandatory_course FROM 'data/dump_folder/program_mandatory_course.csv' WITH (FORMAT csv, HEADER true)
\endif

\if :is_windows
  \set has_program_elective_course `powershell -NoProfile -Command "if (Test-Path 'data\\dump_folder\\program_elective_course.csv') { 'true' } else { 'false' }"`
\else
  \set has_program_elective_course `sh -c "if [ -f 'data/dump_folder/program_elective_course.csv' ]; then echo true; else echo false; fi"`
\endif
\if :has_program_elective_course
  \echo 'Loading program_elective_course...'
  \copy program_elective_course FROM 'data/dump_folder/program_elective_course.csv' WITH (FORMAT csv, HEADER true)
\endif

\if :is_windows
  \set has_program_mandatory_elective_course `powershell -NoProfile -Command "if (Test-Path 'data\\dump_folder\\program_mandatory_elective_course.csv') { 'true' } else { 'false' }"`
\else
  \set has_program_mandatory_elective_course `sh -c "if [ -f 'data/dump_folder/program_mandatory_elective_course.csv' ]; then echo true; else echo false; fi"`
\endif
\if :has_program_mandatory_elective_course
  \echo 'Loading program_mandatory_elective_course...'
  \copy program_mandatory_elective_course FROM 'data/dump_folder/program_mandatory_elective_course.csv' WITH (FORMAT csv, HEADER true)
\endif

\if :is_windows
  \set has_student_requested_enrollment `powershell -NoProfile -Command "if (Test-Path 'data\\dump_folder\\student_requested_enrollment_in_course.csv') { 'true' } else { 'false' }"`
\else
  \set has_student_requested_enrollment `sh -c "if [ -f 'data/dump_folder/student_requested_enrollment_in_course.csv' ]; then echo true; else echo false; fi"`
\endif
\if :has_student_requested_enrollment
  \echo 'Loading student_requested_enrollment_in_course...'
  \copy student_requested_enrollment_in_course FROM 'data/dump_folder/student_requested_enrollment_in_course.csv' WITH (FORMAT csv, HEADER true)
\endif

\if :is_windows
  \set has_student_enrolled `powershell -NoProfile -Command "if (Test-Path 'data\\dump_folder\\student_enrolled_in_course.csv') { 'true' } else { 'false' }"`
\else
  \set has_student_enrolled `sh -c "if [ -f 'data/dump_folder/student_enrolled_in_course.csv' ]; then echo true; else echo false; fi"`
\endif
\if :has_student_enrolled
  \echo 'Loading student_enrolled_in_course...'
  \copy student_enrolled_in_course FROM 'data/dump_folder/student_enrolled_in_course.csv' WITH (FORMAT csv, HEADER true)
\endif

\if :is_windows
  \set has_student_passed `powershell -NoProfile -Command "if (Test-Path 'data\\dump_folder\\student_passed_course.csv') { 'true' } else { 'false' }"`
\else
  \set has_student_passed `sh -c "if [ -f 'data/dump_folder/student_passed_course.csv' ]; then echo true; else echo false; fi"`
\endif
\if :has_student_passed
  \echo 'Loading student_passed_course...'
  \copy student_passed_course FROM 'data/dump_folder/student_passed_course.csv' WITH (FORMAT csv, HEADER true)
\endif

\if :is_windows
  \set has_lesson `powershell -NoProfile -Command "if (Test-Path 'data\\dump_folder\\lesson.csv') { 'true' } else { 'false' }"`
\else
  \set has_lesson `sh -c "if [ -f 'data/dump_folder/lesson.csv' ]; then echo true; else echo false; fi"`
\endif
\if :has_lesson
  \echo 'Loading lesson...'
  \copy lesson FROM 'data/dump_folder/lesson.csv' WITH (FORMAT csv, HEADER true)
\endif

\echo
\echo 'Done. Files that exist were loaded, missing files were skipped.'

