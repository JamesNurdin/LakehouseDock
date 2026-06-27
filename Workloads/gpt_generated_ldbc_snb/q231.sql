WITH tag_counts AS (
    SELECT
        pstu.university_id,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT p.id) AS student_count,
        AVG(pstu.class_year) AS avg_class_year
    FROM person p
    JOIN person_study_at_university pstu
        ON p.id = pstu.person_id
    JOIN person_has_interest_tag phit
        ON p.id = phit.person_id
    JOIN tag t
        ON phit.tag_id = t.id
    GROUP BY pstu.university_id, t.id, t.name
),
total_students AS (
    SELECT
        university_id,
        SUM(student_count) AS total_student_interests
    FROM tag_counts
    GROUP BY university_id
),
tag_proportions AS (
    SELECT
        tc.university_id,
        tc.tag_id,
        tc.tag_name,
        tc.student_count,
        tc.avg_class_year,
        CAST(tc.student_count AS double) / ts.total_student_interests AS interest_proportion
    FROM tag_counts tc
    JOIN total_students ts
        ON tc.university_id = ts.university_id
)
SELECT
    university_id,
    tag_id,
    tag_name,
    student_count,
    avg_class_year,
    interest_proportion
FROM tag_proportions
WHERE interest_proportion > 0.05
ORDER BY university_id, interest_proportion DESC
