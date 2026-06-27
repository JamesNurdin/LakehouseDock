WITH likes_per_student AS (
    SELECT
        pl.person_id,
        COUNT(*) AS likes_count
    FROM person_likes_comment pl
    WHERE pl.creation_date LIKE '2023%'
    GROUP BY pl.person_id
),
students AS (
    SELECT
        psu.person_id,
        psu.university_id,
        psu.class_year,
        p.gender
    FROM person_study_at_university psu
    JOIN person p ON psu.person_id = p.id
)
SELECT
    o.name AS university_name,
    COUNT(DISTINCT s.person_id) AS student_count,
    SUM(COALESCE(l.likes_count, 0)) AS total_likes_by_students,
    AVG(COALESCE(l.likes_count, 0)) AS avg_likes_per_student,
    SUM(CASE WHEN s.gender = 'male' THEN 1 ELSE 0 END) AS male_students,
    SUM(CASE WHEN s.gender = 'female' THEN 1 ELSE 0 END) AS female_students
FROM students s
JOIN organisation o ON s.university_id = o.id
LEFT JOIN likes_per_student l ON s.person_id = l.person_id
GROUP BY o.name
ORDER BY total_likes_by_students DESC
LIMIT 10
