WITH comment_tag_stats AS (
    SELECT
        c.id AS comment_id,
        c.length AS comment_length,
        c.location_country_id AS country_id,
        ct.tag_id,
        c.creator_person_id AS creator_id,
        COUNT(plc.person_id) AS like_cnt
    FROM comment c
    JOIN comment_has_tag_tag ct
        ON ct.comment_id = c.id
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY c.id, c.length, c.location_country_id, ct.tag_id, c.creator_person_id
)
SELECT
    p.name AS country_name,
    ct.tag_id,
    COUNT(*) AS num_comments,
    AVG(ct.comment_length) AS avg_comment_length,
    SUM(ct.like_cnt) AS total_likes,
    COUNT(DISTINCT ct.creator_id) AS distinct_commenters
FROM comment_tag_stats ct
JOIN place p
    ON ct.country_id = p.id
GROUP BY p.name, ct.tag_id
ORDER BY total_likes DESC
LIMIT 10
