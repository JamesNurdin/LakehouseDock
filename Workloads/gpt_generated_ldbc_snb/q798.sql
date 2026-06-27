WITH comment_like_counts AS (
    SELECT
        c.id AS comment_id,
        c.creator_person_id,
        c.length AS comment_length,
        COUNT(plc.person_id) AS like_cnt
    FROM comment c
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY c.id, c.creator_person_id, c.length
)
SELECT
    p.location_city_id,
    COUNT(DISTINCT clc.comment_id) AS total_comments,
    SUM(clc.like_cnt) AS total_likes_received,
    AVG(clc.comment_length) AS avg_comment_length,
    COUNT(DISTINCT p.id) AS distinct_commenters
FROM comment_like_counts clc
JOIN person p
    ON p.id = clc.creator_person_id
GROUP BY p.location_city_id
ORDER BY total_likes_received DESC
LIMIT 20
