WITH student_stats AS (
    SELECT
        psu.university_id,
        psu.class_year,
        COUNT(DISTINCT p.id) AS total_students,
        SUM(CASE WHEN p.gender = 'male' THEN 1 ELSE 0 END) AS male_students,
        SUM(CASE WHEN p.gender = 'female' THEN 1 ELSE 0 END) AS female_students
    FROM person_study_at_university psu
    JOIN person p
        ON psu.person_id = p.id
    GROUP BY psu.university_id, psu.class_year
),
tag_stats AS (
    SELECT
        psu.university_id,
        psu.class_year,
        COUNT(DISTINCT phit.tag_id) AS distinct_interest_tags,
        COUNT(phit.tag_id) AS total_tag_assignments
    FROM person_study_at_university psu
    JOIN person_has_interest_tag phit
        ON psu.person_id = phit.person_id
    GROUP BY psu.university_id, psu.class_year
)
SELECT
    o.id AS university_id,
    o.name AS university_name,
    ss.class_year,
    ss.total_students,
    ss.male_students,
    ss.female_students,
    COALESCE(ts.distinct_interest_tags, 0) AS distinct_interest_tags,
    COALESCE(ts.total_tag_assignments, 0) AS total_tag_assignments,
    CAST(COALESCE(ts.total_tag_assignments, 0) AS double) / NULLIF(ss.total_students, 0) AS avg_tags_per_student
FROM student_stats ss
JOIN organisation o
    ON ss.university_id = o.id
LEFT JOIN tag_stats ts
    ON ss.university_id = ts.university_id
    AND ss.class_year = ts.class_year
WHERE o.type = 'university'
ORDER BY o.name, ss.class_year
