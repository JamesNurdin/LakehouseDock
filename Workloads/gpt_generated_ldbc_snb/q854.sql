WITH student_likes AS (
    SELECT
        psu.university_id,
        p.gender,
        c.id AS comment_id,
        c.length AS comment_length,
        psu.class_year
    FROM person_study_at_university psu
    JOIN person p ON psu.person_id = p.id
    JOIN person_likes_comment plc ON p.id = plc.person_id
    JOIN comment c ON plc.comment_id = c.id
    WHERE psu.class_year >= 2015
)
SELECT
    university_id,
    gender,
    COUNT(DISTINCT comment_id) AS liked_comment_count,
    AVG(comment_length) AS avg_comment_length,
    COUNT(DISTINCT class_year) AS distinct_class_years
FROM student_likes
GROUP BY university_id, gender
ORDER BY liked_comment_count DESC
LIMIT 20
