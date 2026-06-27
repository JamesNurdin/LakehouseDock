WITH comment_tag_country AS (
    SELECT
        c.id AS comment_id,
        c.location_country_id AS country_id,
        ch.tag_id,
        c.length AS comment_length
    FROM comment c
    JOIN comment_has_tag_tag ch
        ON ch.comment_id = c.id
)
SELECT
    t.name AS tag_name,
    p.name AS country_name,
    COUNT(plc.person_id) AS total_likes,
    COUNT(DISTINCT ct.comment_id) AS comment_count,
    AVG(ct.comment_length) AS avg_comment_length
FROM comment_tag_country ct
JOIN tag t
    ON t.id = ct.tag_id
JOIN place p
    ON p.id = ct.country_id
LEFT JOIN person_likes_comment plc
    ON plc.comment_id = ct.comment_id
GROUP BY t.name, p.name
ORDER BY total_likes DESC, comment_count DESC
LIMIT 10
