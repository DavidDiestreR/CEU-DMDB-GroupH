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
-- ============================================================

\pset pager off
\set ON_ERROR_STOP off

\echo
\echo '== Loading CSV files =='
\echo

-- Department
\set has_department `powershell -Command "if (Test-Path 'data\\dump_folder\\department.csv') { 'true' } else { 'false' }"`
\if :has_department
  \echo 'Loading department...'
  \copy public."Department" FROM 'data/dump_folder/department.csv' WITH (FORMAT csv, HEADER true)
\endif

-- Instructor  
\set has_instructor `powershell -Command "if (Test-Path 'data\\dump_folder\\instructor.csv') { 'true' } else { 'false' }"`
\if :has_instructor
  \echo 'Loading instructor...'
  \copy public."Instructor" FROM 'data/dump_folder/instructor.csv' WITH (FORMAT csv, HEADER true)
\endif

-- Program
\set has_program `powershell -Command "if (Test-Path 'data\\dump_folder\\program.csv') { 'true' } else { 'false' }"`
\if :has_program
  \echo 'Loading program...'
  \copy public."Program" FROM 'data/dump_folder/program.csv' WITH (FORMAT csv, HEADER true)
\endif

-- Course
\set has_course `powershell -Command "if (Test-Path 'data\\dump_folder\\course.csv') { 'true' } else { 'false' }"`
\if :has_course
  \echo 'Loading course...'
  \copy public."Course" FROM 'data/dump_folder/course.csv' WITH (FORMAT csv, HEADER true)
\endif

-- Student
\set has_student `powershell -Command "if (Test-Path 'data\\dump_folder\\student.csv') { 'true' } else { 'false' }"`
\if :has_student
  \echo 'Loading student...'
  \copy public."Student" FROM 'data/dump_folder/student.csv' WITH (FORMAT csv, HEADER true)
\endif

-- Department Instructor
\set has_department_instructor `powershell -Command "if (Test-Path 'data\\dump_folder\\department_instructor.csv') { 'true' } else { 'false' }"`
\if :has_department_instructor
  \echo 'Loading department_instructor...'
  \copy public."DEPARTMENT_INSTRUCTOR" FROM 'data/dump_folder/department_instructor.csv' WITH (FORMAT csv, HEADER true)
\endif

-- Teaching Course
\set has_teaching_course `powershell -Command "if (Test-Path 'data\\dump_folder\\teaching_course.csv') { 'true' } else { 'false' }"`
\if :has_teaching_course
  \echo 'Loading teaching_course...'
  \copy public."TEACHING_COURSE" FROM 'data/dump_folder/teaching_course.csv' WITH (FORMAT csv, HEADER true)
\endif

-- Program Required Course
\set has_program_required_course `powershell -Command "if (Test-Path 'data\\dump_folder\\program_required_course.csv') { 'true' } else { 'false' }"`
\if :has_program_required_course
  \echo 'Loading program_required_course...'
  \copy public."PROGRAM_REQUIRED_COURSE" FROM 'data/dump_folder/program_required_course.csv' WITH (FORMAT csv, HEADER true)
\endif

-- Program Elective Course
\set has_program_elective_course `powershell -Command "if (Test-Path 'data\\dump_folder\\program_elective_course.csv') { 'true' } else { 'false' }"`
\if :has_program_elective_course
  \echo 'Loading program_elective_course...'
  \copy public."PROGRAM_ELECTIVE_COURSE" FROM 'data/dump_folder/program_elective_course.csv' WITH (FORMAT csv, HEADER true)
\endif

-- Program Mandatory Elective Course
\set has_program_mandatory_elective_course `powershell -Command "if (Test-Path 'data\\dump_folder\\program_mandatory_elective_course.csv') { 'true' } else { 'false' }"`
\if :has_program_mandatory_elective_course
  \echo 'Loading program_mandatory_elective_course...'
  \copy public."PROGRAM_MANDATORY_ELECTIVE_COURSE" FROM 'data/dump_folder/program_mandatory_elective_course.csv' WITH (FORMAT csv, HEADER true)
\endif

-- Student Requested Enrollment
\set has_student_requested_enrollment `powershell -Command "if (Test-Path 'data\\dump_folder\\student_requested_enrollment_in_course.csv') { 'true' } else { 'false' }"`
\if :has_student_requested_enrollment
  \echo 'Loading student_requested_enrollment_in_course...'
  \copy public."STUDENT_REQUESTED_ENROLLMENT_IN_COURSE" FROM 'data/dump_folder/student_requested_enrollment_in_course.csv' WITH (FORMAT csv, HEADER true)
\endif

-- Student Enrolled
\set has_student_enrolled `powershell -Command "if (Test-Path 'data\\dump_folder\\student_enrolled_in_course.csv') { 'true' } else { 'false' }"`
\if :has_student_enrolled
  \echo 'Loading student_enrolled_in_course...'
  \copy public."STUDENT_ENROLLED_IN_COURSE" FROM 'data/dump_folder/student_enrolled_in_course.csv' WITH (FORMAT csv, HEADER true)
\endif

-- Student Passed Course
\set has_student_passed `powershell -Command "if (Test-Path 'data\\dump_folder\\student_passed_course.csv') { 'true' } else { 'false' }"`
\if :has_student_passed
  \echo 'Loading student_passed_course...'
  \copy public."STUDENT_PASSED_COURSE" FROM 'data/dump_folder/student_passed_course.csv' WITH (FORMAT csv, HEADER true)
\endif

\echo
\echo 'Done. Files that exist were loaded, missing files were skipped.'
