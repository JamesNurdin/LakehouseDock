-- Tag popularity analysis: total comment likes, likes from interested users, and comment statistics per tag
WITH comment_stats AS (
    SELECT
        t.id   AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length)        AS avg_comment_length
    FROM comment_has_tag_tag ct
    JOIN comment c
        ON ct.comment_id = c.id
    JOIN tag t
        ON ct.tag_id = t.id
    GROUP BY
        t.id,
        t.name
),
likes_stats AS (
    SELECT
        t.id   AS tag_id,
        t.name AS tag_name,
        COUNT(*) AS total_likes,
        SUM(CASE WHEN pit.person_id IS NOT NULL THEN 1 ELSE 0 END) AS likes_from_interested
    FROM comment_has_tag_tag ct
    JOIN comment c
        ON ct.comment_id = c.id
    JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    JOIN person p
        ON plc.person_id = p.id
    JOIN tag t
        ON ct.tag_id = t.id
    LEFT JOIN person_has_interest_tag pit
        ON pit.person_id = p.id
        AND pit.tag_id = t.id
    GROUP BY
        t.id,
        t.name
)
SELECT
    cs.tag_id,
    cs.tag_name,
    cs.comment_count,
    cs.avg_comment_length,
    ls.total_likes,
    ls.likes_from_interested,
    (ls.likes_from_interested * 100.0 / NULLIF(ls.total_likes, 0)) AS pct_likes_from_interested
FROM comment_stats cs
JOIN likes_stats ls
    ON cs.tag_id = ls.tag_id
ORDER BY
    ls.total_likes DESC
LIMIT 10
