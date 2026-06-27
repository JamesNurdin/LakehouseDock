WITH comment_likes AS (
    SELECT
        comment_id,
        COUNT(*) AS like_count
    FROM person_likes_comment
    GROUP BY comment_id
),
comment_replies AS (
    SELECT
        parent_comment_id AS comment_id,
        COUNT(*) AS reply_count
    FROM comment
    WHERE parent_comment_id IS NOT NULL
    GROUP BY parent_comment_id
)
SELECT
    t.id AS tag_id,
    t.name AS tag_name,
    COUNT(DISTINCT c.id) AS comment_count,
    SUM(COALESCE(cl.like_count, 0)) AS total_likes,
    AVG(c.length) AS avg_comment_length,
    SUM(COALESCE(cr.reply_count, 0)) AS total_replies,
    (SUM(COALESCE(cl.like_count, 0)) * 1.0) / NULLIF(COUNT(DISTINCT c.id), 0) AS avg_likes_per_comment
FROM comment c
JOIN comment_has_tag_tag cht
    ON cht.comment_id = c.id
JOIN tag t
    ON t.id = cht.tag_id
LEFT JOIN comment_likes cl
    ON cl.comment_id = c.id
LEFT JOIN comment_replies cr
    ON cr.comment_id = c.id
GROUP BY t.id, t.name
ORDER BY total_likes DESC
LIMIT 10
