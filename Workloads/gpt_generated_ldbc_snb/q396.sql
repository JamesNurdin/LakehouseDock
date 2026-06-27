WITH uni_students AS (
    SELECT
        o.id,
        o.name,
        psu.person_id,
        p.gender,
        psu.class_year
    FROM person_study_at_university psu
    JOIN person p ON psu.person_id = p.id
    JOIN organisation o ON psu.university_id = o.id
    WHERE o.type = 'university'
),
uni_counts AS (
    SELECT
        id,
        name,
        class_year,
        COUNT(*) AS total_students,
        COUNT(CASE WHEN gender = 'male' THEN 1 END) AS male_students,
        COUNT(CASE WHEN gender = 'female' THEN 1 END) AS female_students
    FROM uni_students
    GROUP BY id, name, class_year
)
SELECT
    id AS university_id,
    name AS university_name,
    class_year,
    total_students,
    male_students,
    female_students,
    RANK() OVER (ORDER BY total_students DESC) AS university_rank
FROM uni_counts
ORDER BY total_students DESC
LIMIT 20
