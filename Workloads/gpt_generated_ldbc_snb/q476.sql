WITH student_comments AS (
    SELECT
        u.id AS university_id,
        u.name AS university_name,
        c.id AS comment_id,
        c.length AS comment_length
    FROM
        person_study_at_university AS su
        JOIN person AS p ON su.person_id = p.id
        JOIN comment AS c ON c.creator_person_id = p.id
        JOIN organisation AS u ON su.university_id = u.id
    WHERE
        u.type = 'university'
)
SELECT
    sc.university_id,
    sc.university_name,
    COUNT(DISTINCT sc.comment_id) AS comment_count,
    AVG(sc.comment_length) AS avg_comment_length,
    COUNT(plc.person_id) AS total_likes,
    COUNT(DISTINCT cht.tag_id) AS distinct_tag_count,
    (COUNT(plc.person_id) * 1.0) / COUNT(DISTINCT sc.comment_id) AS avg_likes_per_comment
FROM
    student_comments AS sc
    LEFT JOIN person_likes_comment AS plc ON plc.comment_id = sc.comment_id
    LEFT JOIN comment_has_tag_tag AS cht ON cht.comment_id = sc.comment_id
GROUP BY
    sc.university_id,
    sc.university_name
ORDER BY
    total_likes DESC
LIMIT 10
