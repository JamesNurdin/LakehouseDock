/*
  Average number of likes per comment made by students of each university
*/
WITH comment_likes AS (
    SELECT
        org.id   AS university_id,
        org.name AS university_name,
        c.id     AS comment_id,
        COUNT(plc.person_id) AS likes_count
    FROM comment c
    JOIN person p
        ON c.creator_person_id = p.id
    JOIN person_study_at_university stu
        ON stu.person_id = p.id
    JOIN organisation org
        ON stu.university_id = org.id
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    WHERE org.type = 'university'
    GROUP BY org.id, org.name, c.id
)
SELECT
    university_id,
    university_name,
    COUNT(comment_id)           AS comment_count,
    SUM(likes_count)            AS total_likes,
    AVG(likes_count)            AS avg_likes_per_comment
FROM comment_likes
GROUP BY university_id, university_name
ORDER BY avg_likes_per_comment DESC
LIMIT 10
