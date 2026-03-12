\set ON_ERROR_STOP on
\pset pager off

-- ============================================================
-- example_queries.sql
-- Sample queries for the course information system.
--
-- Usage (recommended):
--   1) Set variables in .env:
--      DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD, SCHEMA
--   2) Run the make target:
--      make queries
-- ============================================================

\if :{?schema}
\else
  \set schema sandbox
\endif

SET search_path TO :"schema";


-- ============================================================
-- QUERY 1: Available courses for a given student
--
-- Shows courses from the student's program (required, elective,
-- mandatory-elective) that the student has not yet passed,
-- is not currently enrolled in, and whose year gate they meet.
-- ============================================================

SELECT c.course_code,
       c.course_name,
       c.course_credits,
       t.term_name,
       'Required' AS course_type,
       prc.available_from_year_n
FROM student s
JOIN program_mandatory_course prc ON s.program_id = prc.program_id
JOIN course c                    ON prc.course_id = c.course_id
JOIN term t                      ON c.term_id = t.term_id
WHERE s.student_id = 2
  AND prc.available_from_year_n <= EXTRACT(YEAR FROM CURRENT_DATE) - s.student_start_year + 1
  AND c.course_id NOT IN (SELECT course_id FROM student_passed_course   WHERE student_id = s.student_id)
  AND c.course_id NOT IN (SELECT course_id FROM student_enrolled_in_course WHERE student_id = s.student_id)

UNION ALL

SELECT c.course_code,
       c.course_name,
       c.course_credits,
       t.term_name,
       'Elective' AS course_type,
       pec.available_from_year_n
FROM student s
JOIN program_elective_course pec ON s.program_id = pec.program_id
JOIN course c                    ON pec.course_id = c.course_id
JOIN term t                      ON c.term_id = t.term_id
WHERE s.student_id = 2
  AND pec.available_from_year_n <= EXTRACT(YEAR FROM CURRENT_DATE) - s.student_start_year + 1
  AND c.course_id NOT IN (SELECT course_id FROM student_passed_course   WHERE student_id = s.student_id)
  AND c.course_id NOT IN (SELECT course_id FROM student_enrolled_in_course WHERE student_id = s.student_id)

UNION ALL

SELECT c.course_code,
       c.course_name,
       c.course_credits,
       t.term_name,
       'Mandatory Elective' AS course_type,
       pmec.available_from_year_n
FROM student s
JOIN program_mandatory_elective_course pmec ON s.program_id = pmec.program_id
JOIN course c                               ON pmec.course_id = c.course_id
JOIN term t                                 ON c.term_id = t.term_id
WHERE s.student_id = 2
  AND pmec.available_from_year_n <= EXTRACT(YEAR FROM CURRENT_DATE) - s.student_start_year + 1
  AND c.course_id NOT IN (SELECT course_id FROM student_passed_course   WHERE student_id = s.student_id)
  AND c.course_id NOT IN (SELECT course_id FROM student_enrolled_in_course WHERE student_id = s.student_id)

ORDER BY course_type, course_code;


-- ============================================================
-- QUERY 2: Prerequisite check for enrollment requests
--
-- For each pending request, checks whether all hard prerequisites
-- (if any) have been passed and labels the request accordingly.
-- ============================================================

SELECT s.student_first_name || ' ' || s.student_last_name AS student_name,
       c.course_code,
       c.course_name,
       COALESCE(
         STRING_AGG(prereq.course_name, ', ' ORDER BY prereq.course_name),
         'None'
       ) AS hard_prerequisites,
       c.prereq_text       AS soft_prerequisites,
       CASE
           WHEN COUNT(chpc.hard_prerequisite_course_id) = 0
                THEN 'AUTO-APPROVE'
           WHEN COUNT(spc.course_id) = COUNT(chpc.hard_prerequisite_course_id)
                THEN 'AUTO-APPROVE'
           ELSE 'FLAG: prerequisites not met'
       END AS decision
FROM student_requested_enrollment_in_course req
JOIN student s      ON req.student_id = s.student_id
JOIN course  c      ON req.course_id  = c.course_id
LEFT JOIN course_has_hard_prerequisite_course chpc
       ON chpc.course_id = c.course_id
LEFT JOIN course prereq
       ON prereq.course_id = chpc.hard_prerequisite_course_id
LEFT JOIN student_passed_course spc
       ON spc.student_id = req.student_id
      AND spc.course_id  = chpc.hard_prerequisite_course_id
GROUP BY req.student_id,
         req.course_id,
         s.student_first_name,
         s.student_last_name,
         c.course_code,
         c.course_name,
         c.prereq_text
ORDER BY decision, s.student_last_name;


-- ============================================================
-- QUERY 3: Credit progress per student
--
-- For each student shows total mandatory credits required by
-- their program, how many they have passed, and the remainder.
-- ============================================================

SELECT s.student_first_name || ' ' || s.student_last_name AS student_name,
       p.program_name,
       SUM(c.course_credits)                               AS total_mandatory_credits,
       COALESCE(SUM(c.course_credits)
                FILTER (WHERE spc.student_id IS NOT NULL), 0) AS passed_mandatory_credits,
       SUM(c.course_credits)
         - COALESCE(SUM(c.course_credits)
                    FILTER (WHERE spc.student_id IS NOT NULL), 0) AS remaining_mandatory
FROM student s
JOIN program p                    ON s.program_id  = p.program_id
JOIN program_mandatory_course prc  ON p.program_id  = prc.program_id
JOIN course c                     ON prc.course_id = c.course_id
LEFT JOIN student_passed_course spc
       ON spc.student_id = s.student_id
      AND spc.course_id  = prc.course_id
GROUP BY s.student_id, s.student_first_name, s.student_last_name, p.program_name
ORDER BY student_name;
