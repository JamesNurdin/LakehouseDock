WITH comment_tag_metrics AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT c.id) AS total_comments,
        AVG(c.length) AS avg_comment_length,
        SUM(CASE WHEN pc.id IS NOT NULL THEN 1 ELSE 0 END) AS reply_comments
    FROM comment_has_tag_tag cht
    JOIN comment c ON cht.comment_id = c.id
    LEFT JOIN comment pc ON c.parent_comment_id = pc.id
    JOIN tag t ON cht.tag_id = t.id
    GROUP BY t.id, t.name
),
post_tag_metrics AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT pht.post_id) AS total_posts
    FROM post_has_tag_tag pht
    JOIN tag t ON pht.tag_id = t.id
    GROUP BY t.id
)
SELECT
    ct.tag_id,
    ct.tag_name,
    ct.total_comments,
    ct.avg_comment_length,
    ct.reply_comments,
    COALESCE(pt.total_posts, 0) AS total_posts
FROM comment_tag_metrics ct
LEFT JOIN post_tag_metrics pt ON ct.tag_id = pt.tag_id
ORDER BY ct.total_comments DESC
LIMIT 20
