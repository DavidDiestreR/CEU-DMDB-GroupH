CREATE TABLE courses_1nf AS
SELECT 
    course_code,
    course_name,
    term,
    -- Converting "Yes/No" strings to Boolean for 'allow_repeats'
    CASE WHEN allow_repeats = 'Yes' THEN TRUE ELSE FALSE END AS allow_repeats,
    us_credits,
    instructor,
    level,
    -- THE 1NF TRANSFORMATION:
    trim(unnest(string_to_array(corresponding_programs, ','))) AS program_name,
    abbreviation,
    course_type,
    department,
    corresponding_collections_codes,
    corresponding_collections,
    corresponding_program_codes,
    marking_scheme,
    offered_for_non_degree_students,
    scheme,
    ects,
    learning_outcomes,
    learning_activities_and_teaching_methods,
    assessment,
    course_contents,
    background_and_overall_aim,
    contact_details,
    course_prerequisites,
    instructor_email
FROM 
    raw_data;