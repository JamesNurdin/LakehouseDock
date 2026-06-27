WITH student_comments AS (
    SELECT
        psu.university_id,
        p.id AS person_id,
        c.id AS comment_id,
        c.length AS comment_length,
        c.location_country_id
    FROM person_study_at_university psu
    JOIN person p
        ON psu.person_id = p.id
    JOIN comment c
        ON c.creator_person_id = p.id
    JOIN organisation o
        ON psu.university_id = o.id
    WHERE o.type = 'university'
)
SELECT
    o.name AS university_name,
    o.id   AS university_id,
    COUNT(DISTINCT sc.person_id)   AS distinct_student_count,
    COUNT(sc.comment_id)           AS total_comments,
    AVG(sc.comment_length)         AS avg_comment_length,
    COUNT(DISTINCT pl.name)        AS distinct_comment_countries
FROM student_comments sc
JOIN organisation o
    ON sc.university_id = o.id
LEFT JOIN place pl
    ON sc.location_country_id = pl.id
GROUP BY o.id, o.name
ORDER BY total_comments DESC
LIMIT 10
