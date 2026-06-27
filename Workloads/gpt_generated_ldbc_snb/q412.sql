WITH student_comments AS (
    SELECT
        c.id AS comment_id,
        c.creation_date AS comment_creation_date,
        c.length AS comment_length,
        c.location_country_id AS comment_country_id,
        p.id AS person_id,
        psu.university_id,
        u.name AS university_name
    FROM comment c
    JOIN person p ON c.creator_person_id = p.id
    JOIN person_study_at_university psu ON psu.person_id = p.id
    JOIN organisation u ON psu.university_id = u.id
    WHERE u.type = 'university'
)
SELECT
    sc.university_name,
    YEAR(DATE_PARSE(sc.comment_creation_date, '%Y-%m-%d')) AS comment_year,
    pl.name AS comment_country,
    COUNT(sc.comment_id) AS comment_count,
    AVG(sc.comment_length) AS avg_comment_length,
    COUNT(DISTINCT sc.person_id) AS distinct_student_commenters
FROM student_comments sc
JOIN place pl ON sc.comment_country_id = pl.id
WHERE YEAR(DATE_PARSE(sc.comment_creation_date, '%Y-%m-%d')) >= 2020
GROUP BY
    sc.university_name,
    YEAR(DATE_PARSE(sc.comment_creation_date, '%Y-%m-%d')),
    pl.name
ORDER BY comment_count DESC
LIMIT 100
