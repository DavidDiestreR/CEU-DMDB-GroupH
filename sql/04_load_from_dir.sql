\set ON_ERROR_STOP on
\pset pager off

-- ============================================================
-- Generic data loader (psql script)
-- Loads any CSVs found in a given directory (skips missing files)
--
-- Usage:
--   psql -v schema=sandbox -v data_dir=data/public/v1 -f sql/04_load_from_dir.sql "<conn>"
--
-- Optional flags:
--   -v truncate=1   : TRUNCATE tables in the target schema before loading
--   -v strict=1     : stop if a file to be loaded depends on missing/empty parent tables
--   -v header=1     : CSV files include header row (default 1). Use -v header=0 otherwise.
--
-- Expected filenames inside :data_dir (lowercase):
--   department.csv
--   instructor.csv
--   program.csv
--   course.csv
--   student.csv
--   student_requested_enrollment_in_course.csv
--   student_enrolled_in_course.csv
--   student_passed_course.csv
--   teaching_course.csv
--   department_instructor.csv
--   program_required_course.csv
--   program_elective_course.csv
--   program_mandatory_elective_course.csv
--
-- NOTE: .xlsx cannot be imported directly by psql/\copy.
--       Convert Excel to CSV first (one CSV per table).
-- ============================================================

-- ---- Required variable: data_dir
\if :{?data_dir}
\else
  \echo 'ERROR: data_dir is not set.'
  \echo 'Example: psql -v schema=sandbox -v data_dir=data/public/v1 -f sql/04_load_from_dir.sql "<conn>"'
  \quit 1
\endif

-- ---- Optional variables with defaults
\if :{?schema}
\else
  \set schema sandbox
\endif

\if :{?truncate}
\else
  \set truncate 0
\endif

\if :{?strict}
\else
  \set strict 0
\endif

\if :{?header}
\else
  \set header 1
\endif

\echo ''
\echo '== Loader config =='
\echo 'schema   : :'schema''
\echo 'data_dir : :'data_dir''
\echo 'truncate : :'truncate''
\echo 'strict   : :'strict''
\echo 'header   : :'header''
\echo ''

-- Build full file paths (psql-level string concatenation by substitution)
\set f_department                              :data_dir/department.csv
\set f_instructor                              :data_dir/instructor.csv
\set f_program                                 :data_dir/program.csv
\set f_course                                  :data_dir/course.csv
\set f_student                                 :data_dir/student.csv
\set f_student_requested_enrollment_in_course  :data_dir/student_requested_enrollment_in_course.csv
\set f_student_enrolled_in_course              :data_dir/student_enrolled_in_course.csv
\set f_student_passed_course                   :data_dir/student_passed_course.csv
\set f_teaching_course                         :data_dir/teaching_course.csv
\set f_department_instructor                   :data_dir/department_instructor.csv
\set f_program_required_course                 :data_dir/program_required_course.csv
\set f_program_elective_course                 :data_dir/program_elective_course.csv
\set f_program_mandatory_elective_course       :data_dir/program_mandatory_elective_course.csv

-- Detect file presence (POSIX shell).
-- If you run on Windows, use WSL/Git Bash.
\set has_department                              `test -f ":f_department" && echo 1 || echo 0`
\set has_instructor                              `test -f ":f_instructor" && echo 1 || echo 0`
\set has_program                                 `test -f ":f_program" && echo 1 || echo 0`
\set has_course                                  `test -f ":f_course" && echo 1 || echo 0`
\set has_student                                 `test -f ":f_student" && echo 1 || echo 0`
\set has_student_requested_enrollment_in_course  `test -f ":f_student_requested_enrollment_in_course" && echo 1 || echo 0`
\set has_student_enrolled_in_course              `test -f ":f_student_enrolled_in_course" && echo 1 || echo 0`
\set has_student_passed_course                   `test -f ":f_student_passed_course" && echo 1 || echo 0`
\set has_teaching_course                         `test -f ":f_teaching_course" && echo 1 || echo 0`
\set has_department_instructor                   `test -f ":f_department_instructor" && echo 1 || echo 0`
\set has_program_required_course                 `test -f ":f_program_required_course" && echo 1 || echo 0`
\set has_program_elective_course                 `test -f ":f_program_elective_course" && echo 1 || echo 0`
\set has_program_mandatory_elective_course       `test -f ":f_program_mandatory_elective_course" && echo 1 || echo 0`

\echo '== Files detected =='
\echo 'department.csv                              : :'has_department''
\echo 'instructor.csv                              : :'has_instructor''
\echo 'program.csv                                 : :'has_program''
\echo 'course.csv                                  : :'has_course''
\echo 'student.csv                                 : :'has_student''
\echo 'student_requested_enrollment_in_course.csv  : :'has_student_requested_enrollment_in_course''
\echo 'student_enrolled_in_course.csv              : :'has_student_enrolled_in_course''
\echo 'student_passed_course.csv                   : :'has_student_passed_course''
\echo 'teaching_course.csv                         : :'has_teaching_course''
\echo 'department_instructor.csv                   : :'has_department_instructor''
\echo 'program_required_course.csv                 : :'has_program_required_course''
\echo 'program_elective_course.csv                 : :'has_program_elective_course''
\echo 'program_mandatory_elective_course.csv       : :'has_program_mandatory_elective_course''
\echo ''

-- Optional truncate (useful for re-running loads)
\if :truncate = 1
  \echo '== Truncating tables (CASCADE) =='
  TRUNCATE TABLE
    :"schema"."PROGRAM_MANDATORY_ELECTIVE_COURSE",
    :"schema"."PROGRAM_ELECTIVE_COURSE",
    :"schema"."PROGRAM_REQUIRED_COURSE",
    :"schema"."DEPARTMENT_INSTRUCTOR",
    :"schema"."TEACHING_COURSE",
    :"schema"."STUDENT_PASSED_COURSE",
    :"schema"."STUDENT_ENROLLED_IN_COURSE",
    :"schema"."STUDENT_REQUESTED_ENROLLMENT_IN_COURSE",
    :"schema"."Student",
    :"schema"."Course",
    :"schema"."Program",
    :"schema"."Instructor",
    :"schema"."Department"
  CASCADE;
  \echo ''
\endif

-- Helper: get current row counts for strict dependency checks
SELECT COUNT(*) AS dept_count   FROM :"schema"."Department"; \gset
SELECT COUNT(*) AS instr_count  FROM :"schema"."Instructor"; \gset
SELECT COUNT(*) AS prog_count   FROM :"schema"."Program";    \gset
SELECT COUNT(*) AS course_count FROM :"schema"."Course";     \gset
SELECT COUNT(*) AS stud_count   FROM :"schema"."Student";    \gset

-- ============================================================
-- Load in dependency order
-- ============================================================

\echo '== Loading tables =='

-- Department
\if :has_department = 1
  \echo 'Loading Department from :'f_department''
  \copy :"schema"."Department"(department_id) FROM :'f_department' WITH (FORMAT csv, HEADER :header);
\else
  \echo 'Skipping Department (file not found)'
\endif
SELECT COUNT(*) AS dept_count FROM :"schema"."Department"; \gset

-- Instructor (independent)
\if :has_instructor = 1
  \echo 'Loading Instructor from :'f_instructor''
  \copy :"schema"."Instructor"(instructor_id) FROM :'f_instructor' WITH (FORMAT csv, HEADER :header);
\else
  \echo 'Skipping Instructor (file not found)'
\endif
SELECT COUNT(*) AS instr_count FROM :"schema"."Instructor"; \gset

-- Program depends on Department
\if :has_program = 1
  \if :strict = 1
    \if :dept_count = 0
      \echo 'ERROR: program.csv found but Department is empty. Load department.csv first (or disable strict).'
      \quit 1
    \endif
  \endif
  \echo 'Loading Program from :'f_program''
  \copy :"schema"."Program"(program_id, department_id) FROM :'f_program' WITH (FORMAT csv, HEADER :header);
\else
  \echo 'Skipping Program (file not found)'
\endif
SELECT COUNT(*) AS prog_count FROM :"schema"."Program"; \gset

-- Course depends on Department (and may self-reference)
\if :has_course = 1
  \if :strict = 1
    \if :dept_count = 0
      \echo 'ERROR: course.csv found but Department is empty. Load department.csv first (or disable strict).'
      \quit 1
    \endif
  \endif
  \echo 'Loading Course from :'f_course''
  \copy :"schema"."Course"(course_id, department_id, excludes_course_id, hard_prerequisite_course_id)
    FROM :'f_course' WITH (FORMAT csv, HEADER :header);
\else
  \echo 'Skipping Course (file not found)'
\endif
SELECT COUNT(*) AS course_count FROM :"schema"."Course"; \gset

-- Student depends on Program
\if :has_student = 1
  \if :strict = 1
    \if :prog_count = 0
      \echo 'ERROR: student.csv found but Program is empty. Load program.csv first (or disable strict).'
      \quit 1
    \endif
  \endif
  \echo 'Loading Student from :'f_student''
  \copy :"schema"."Student"(student_id, program_id) FROM :'f_student' WITH (FORMAT csv, HEADER :header);
\else
  \echo 'Skipping Student (file not found)'
\endif
SELECT COUNT(*) AS stud_count FROM :"schema"."Student"; \gset

-- Junction tables (depend on their parent tables)
\if :has_department_instructor = 1
  \if :strict = 1
    \if :dept_count = 0
      \echo 'ERROR: department_instructor.csv found but Department is empty.'
      \quit 1
    \endif
    \if :instr_count = 0
      \echo 'ERROR: department_instructor.csv found but Instructor is empty.'
      \quit 1
    \endif
  \endif
  \echo 'Loading DEPARTMENT_INSTRUCTOR from :'f_department_instructor''
  \copy :"schema"."DEPARTMENT_INSTRUCTOR"(department_id, instructor_id)
    FROM :'f_department_instructor' WITH (FORMAT csv, HEADER :header);
\else
  \echo 'Skipping DEPARTMENT_INSTRUCTOR (file not found)'
\endif

\if :has_teaching_course = 1
  \if :strict = 1
    \if :instr_count = 0
      \echo 'ERROR: teaching_course.csv found but Instructor is empty.'
      \quit 1
    \endif
    \if :course_count = 0
      \echo 'ERROR: teaching_course.csv found but Course is empty.'
      \quit 1
    \endif
  \endif
  \echo 'Loading TEACHING_COURSE from :'f_teaching_course''
  \copy :"schema"."TEACHING_COURSE"(instructor_id, course_id)
    FROM :'f_teaching_course' WITH (FORMAT csv, HEADER :header);
\else
  \echo 'Skipping TEACHING_COURSE (file not found)'
\endif

\if :has_program_required_course = 1
  \if :strict = 1
    \if :prog_count = 0
      \echo 'ERROR: program_required_course.csv found but Program is empty.'
      \quit 1
    \endif
    \if :course_count = 0
      \echo 'ERROR: program_required_course.csv found but Course is empty.'
      \quit 1
    \endif
  \endif
  \echo 'Loading PROGRAM_REQUIRED_COURSE from :'f_program_required_course''
  \copy :"schema"."PROGRAM_REQUIRED_COURSE"(program_id, course_id)
    FROM :'f_program_required_course' WITH (FORMAT csv, HEADER :header);
\else
  \echo 'Skipping PROGRAM_REQUIRED_COURSE (file not found)'
\endif

\if :has_program_elective_course = 1
  \if :strict = 1
    \if :prog_count = 0
      \echo 'ERROR: program_elective_course.csv found but Program is empty.'
      \quit 1
    \endif
    \if :course_count = 0
      \echo 'ERROR: program_elective_course.csv found but Course is empty.'
      \quit 1
    \endif
  \endif
  \echo 'Loading PROGRAM_ELECTIVE_COURSE from :'f_program_elective_course''
  \copy :"schema"."PROGRAM_ELECTIVE_COURSE"(program_id, course_id)
    FROM :'f_program_elective_course' WITH (FORMAT csv, HEADER :header);
\else
  \echo 'Skipping PROGRAM_ELECTIVE_COURSE (file not found)'
\endif

\if :has_program_mandatory_elective_course = 1
  \if :strict = 1
    \if :prog_count = 0
      \echo 'ERROR: program_mandatory_elective_course.csv found but Program is empty.'
      \quit 1
    \endif
    \if :course_count = 0
      \echo 'ERROR: program_mandatory_elective_course.csv found but Course is empty.'
      \quit 1
    \endif
  \endif
  \echo 'Loading PROGRAM_MANDATORY_ELECTIVE_COURSE from :'f_program_mandatory_elective_course''
  \copy :"schema"."PROGRAM_MANDATORY_ELECTIVE_COURSE"(program_id, course_id)
    FROM :'f_program_mandatory_elective_course' WITH (FORMAT csv, HEADER :header);
\else
  \echo 'Skipping PROGRAM_MANDATORY_ELECTIVE_COURSE (file not found)'
\endif

\if :has_student_requested_enrollment_in_course = 1
  \if :strict = 1
    \if :stud_count = 0
      \echo 'ERROR: student_requested_enrollment_in_course.csv found but Student is empty.'
      \quit 1
    \endif
    \if :course_count = 0
      \echo 'ERROR: student_requested_enrollment_in_course.csv found but Course is empty.'
      \quit 1
    \endif
  \endif
  \echo 'Loading STUDENT_REQUESTED_ENROLLMENT_IN_COURSE from :'f_student_requested_enrollment_in_course''
  \copy :"schema"."STUDENT_REQUESTED_ENROLLMENT_IN_COURSE"(student_id, course_id)
    FROM :'f_student_requested_enrollment_in_course' WITH (FORMAT csv, HEADER :header);
\else
  \echo 'Skipping STUDENT_REQUESTED_ENROLLMENT_IN_COURSE (file not found)'
\endif

\if :has_student_enrolled_in_course = 1
  \if :strict = 1
    \if :stud_count = 0
      \echo 'ERROR: student_enrolled_in_course.csv found but Student is empty.'
      \quit 1
    \endif
    \if :course_count = 0
      \echo 'ERROR: student_enrolled_in_course.csv found but Course is empty.'
      \quit 1
    \endif
  \endif
  \echo 'Loading STUDENT_ENROLLED_IN_COURSE from :'f_student_enrolled_in_course''
  \copy :"schema"."STUDENT_ENROLLED_IN_COURSE"(student_id, course_id)
    FROM :'f_student_enrolled_in_course' WITH (FORMAT csv, HEADER :header);
\else
  \echo 'Skipping STUDENT_ENROLLED_IN_COURSE (file not found)'
\endif

\if :has_student_passed_course = 1
  \if :strict = 1
    \if :stud_count = 0
      \echo 'ERROR: student_passed_course.csv found but Student is empty.'
      \quit 1
    \endif
    \if :course_count = 0
      \echo 'ERROR: student_passed_course.csv found but Course is empty.'
      \quit 1
    \endif
  \endif
  \echo 'Loading STUDENT_PASSED_COURSE from :'f_student_passed_course''
  \copy :"schema"."STUDENT_PASSED_COURSE"(student_id, course_id)
    FROM :'f_student_passed_course' WITH (FORMAT csv, HEADER :header);
\else
  \echo 'Skipping STUDENT_PASSED_COURSE (file not found)'
\endif

\echo ''
\echo '== Final row counts =='
SELECT 'Department' AS table, COUNT(*) FROM :"schema"."Department"
UNION ALL SELECT 'Instructor', COUNT(*) FROM :"schema"."Instructor"
UNION ALL SELECT 'Program', COUNT(*) FROM :"schema"."Program"
UNION ALL SELECT 'Course', COUNT(*) FROM :"schema"."Course"
UNION ALL SELECT 'Student', COUNT(*) FROM :"schema"."Student"
UNION ALL SELECT 'STUDENT_REQUESTED_ENROLLMENT_IN_COURSE', COUNT(*) FROM :"schema"."STUDENT_REQUESTED_ENROLLMENT_IN_COURSE"
UNION ALL SELECT 'STUDENT_ENROLLED_IN_COURSE', COUNT(*) FROM :"schema"."STUDENT_ENROLLED_IN_COURSE"
UNION ALL SELECT 'STUDENT_PASSED_COURSE', COUNT(*) FROM :"schema"."STUDENT_PASSED_COURSE"
UNION ALL SELECT 'TEACHING_COURSE', COUNT(*) FROM :"schema"."TEACHING_COURSE"
UNION ALL SELECT 'DEPARTMENT_INSTRUCTOR', COUNT(*) FROM :"schema"."DEPARTMENT_INSTRUCTOR"
UNION ALL SELECT 'PROGRAM_REQUIRED_COURSE', COUNT(*) FROM :"schema"."PROGRAM_REQUIRED_COURSE"
UNION ALL SELECT 'PROGRAM_ELECTIVE_COURSE', COUNT(*) FROM :"schema"."PROGRAM_ELECTIVE_COURSE"
UNION ALL SELECT 'PROGRAM_MANDATORY_ELECTIVE_COURSE', COUNT(*) FROM :"schema"."PROGRAM_MANDATORY_ELECTIVE_COURSE"
ORDER BY 1;

\echo ''
\echo 'Done.'
