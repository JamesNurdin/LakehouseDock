WITH comment_tag_info AS (
    SELECT
        c.id AS comment_id,
        c.length AS comment_length,
        c.location_country_id AS country_id,
        c.parent_post_id AS post_id,
        ct.tag_id AS tag_id,
        plc.person_id AS liker_person_id
    FROM comment c
    JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
)
SELECT
    t.id AS tag_id,
    t.name AS tag_name,
    p.id AS country_id,
    p.name AS country_name,
    COUNT(DISTINCT ct_info.comment_id) AS comment_count,
    COUNT(ct_info.liker_person_id) AS like_count,
    AVG(ct_info.comment_length) AS avg_comment_length,
    COUNT(DISTINCT po.id) AS distinct_post_count
FROM comment_tag_info ct_info
JOIN tag t ON t.id = ct_info.tag_id
JOIN place p ON p.id = ct_info.country_id
LEFT JOIN post po ON po.id = ct_info.post_id
GROUP BY t.id, t.name, p.id, p.name
ORDER BY like_count DESC
LIMIT 10
