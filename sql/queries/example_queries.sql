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
-- Change the student_id in the WHERE clauses to inspect a different student.
-- is not currently enrolled in, and whose year gate they meet.
-- ============================================================

SELECT c.course_code,
       c.course_name,
       c.ects_credits,
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
       c.ects_credits,
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
       c.ects_credits,
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
ORDER BY decision, s.student_last_name
LIMIT 5;


-- ============================================================
-- QUERY 3: Credit progress for one student
--
-- For one student shows total mandatory ECTS credits required by
-- their program, how many they have passed, and the remainder.
-- Change the student_id in the WHERE clause to inspect a different student.
-- ============================================================

SELECT s.student_first_name || ' ' || s.student_last_name AS student_name,
       p.program_name,
       SUM(c.ects_credits)                               AS total_mandatory_ects_credits,
       COALESCE(SUM(c.ects_credits)
                FILTER (WHERE spc.student_id IS NOT NULL), 0) AS passed_mandatory_ects_credits,
       SUM(c.ects_credits)
         - COALESCE(SUM(c.ects_credits)
                    FILTER (WHERE spc.student_id IS NOT NULL), 0) AS remaining_mandatory
FROM student s
JOIN program p                    ON s.program_id  = p.program_id
JOIN program_mandatory_course prc  ON p.program_id  = prc.program_id
JOIN course c                     ON prc.course_id = c.course_id
LEFT JOIN student_passed_course spc
       ON spc.student_id = s.student_id
      AND spc.course_id  = prc.course_id
WHERE s.student_id = 2
GROUP BY s.student_id, s.student_first_name, s.student_last_name, p.program_name;


-- ============================================================
-- QUERY 4: Class rescheduling
--
-- For a target course, returns the common free time windows shared by
-- all enrolled students between 08:20 and 19:20, Monday to Friday.
-- The target course is only used to choose which students to inspect.
-- Its own lessons are also treated as occupied time, so those slots
-- never appear as free results.
--
-- Change the course_id in params to test a different course.
-- Lessons are modeled as recurring weekly slots.
-- ============================================================

WITH params AS (
  -- Input parameter: target course whose enrolled students we inspect.
  SELECT 1::int AS course_id
),
weekday_order AS (
  -- Static weekday lookup used to enforce Monday-to-Friday ordering.
  SELECT *
  FROM (VALUES
    (1, 'monday'),
    (2, 'tuesday'),
    (3, 'wednesday'),
    (4, 'thursday'),
    (5, 'friday')
  ) AS t(weekday_number, weekday)
),
course_students AS (
  -- Students enrolled in the target course.
  SELECT sec.student_id
  FROM student_enrolled_in_course sec
  JOIN params p ON p.course_id = sec.course_id
),
occupied_lessons AS (
  -- Busy intervals for those students, clipped to the daily scheduling window.
  SELECT DISTINCT
         wo.weekday_number,
         wo.weekday,
         GREATEST(l.start_time, TIME '08:20') AS busy_start,
         LEAST(l.end_time, TIME '19:20') AS busy_end
  FROM course_students cs
  JOIN student_enrolled_in_course sec
    ON sec.student_id = cs.student_id
  JOIN lesson l
    ON l.course_id = sec.course_id
  JOIN weekday_order wo
    ON wo.weekday = lower(l.weekday)
  WHERE l.end_time > TIME '08:20'
    AND l.start_time < TIME '19:20'
    AND GREATEST(l.start_time, TIME '08:20') < LEAST(l.end_time, TIME '19:20')
),
running_busy AS (
  -- For each row, keep the latest end time reached by its overlapping busy intervals on that day.
  SELECT weekday_number,
         weekday,
         busy_start,
         busy_end,
         MAX(busy_end) OVER (
           PARTITION BY weekday_number
           ORDER BY busy_start, busy_end
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
         ) AS running_busy_end
  FROM occupied_lessons
),
busy_groups AS (
  -- Number the busy intervals so overlapping or touching rows end up in the same group.
  SELECT weekday_number,
         weekday,
         busy_start,
         busy_end,
         SUM(
           CASE
             WHEN previous_running_busy_end IS NULL
                  OR busy_start > previous_running_busy_end THEN 1
             ELSE 0
           END
         ) OVER (
           PARTITION BY weekday_number
           ORDER BY busy_start, busy_end
         ) AS group_id
  FROM (
    SELECT weekday_number,
           weekday,
           busy_start,
           busy_end,
           LAG(running_busy_end) OVER (
             PARTITION BY weekday_number
             ORDER BY busy_start, busy_end
           ) AS previous_running_busy_end
    FROM running_busy
  ) x
),
merged_busy AS (
  -- Merge each busy group into a single occupied interval.
  SELECT weekday_number,
         weekday,
         MIN(busy_start) AS busy_start,
         MAX(busy_end) AS busy_end
  FROM busy_groups
  GROUP BY weekday_number, weekday, group_id
),
day_bounds AS (
  -- Daily boundaries for the search window on each weekday.
  SELECT weekday_number,
         weekday,
         TIME '08:20' AS day_start,
         TIME '19:20' AS day_end
  FROM weekday_order
),
busy_with_sentinel AS (
  -- Add a day-end sentinel so the last free slot of each day can be computed.
  SELECT weekday_number,
         weekday,
         busy_start,
         busy_end
  FROM merged_busy

  UNION ALL

  SELECT weekday_number,
         weekday,
         day_end AS busy_start,
         day_end AS busy_end
  FROM day_bounds
),
free_slots AS (
  -- Compute gaps between merged busy intervals as candidate free slots.
  SELECT bws.weekday_number,
         bws.weekday AS weekday,
         COALESCE(
           LAG(bws.busy_end) OVER (
             PARTITION BY bws.weekday_number
             ORDER BY bws.busy_start, bws.busy_end
           ),
           db.day_start
         ) AS free_start,
         bws.busy_start AS free_end
  FROM busy_with_sentinel bws
  JOIN day_bounds db
    ON db.weekday_number = bws.weekday_number
)
SELECT fs.weekday,
       fs.free_start,
       fs.free_end,
       fs.free_end - fs.free_start AS free_duration,
       (
         SELECT STRING_AGG(c.class_name, ', ' ORDER BY c.class_name)
         FROM class c
         WHERE NOT EXISTS (
           SELECT 1
           FROM lesson l
           WHERE l.class_id = c.class_id
             AND lower(l.weekday) = lower(fs.weekday)
             AND l.start_time < fs.free_end
             AND l.end_time > fs.free_start
         )
       ) AS rooms_available
FROM free_slots fs
WHERE fs.free_start < fs.free_end
ORDER BY fs.weekday_number, fs.free_start;