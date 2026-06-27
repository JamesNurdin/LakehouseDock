WITH comment_stats AS (
    SELECT
        ct.tag_id,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment_has_tag_tag ct
    JOIN comment c ON ct.comment_id = c.id
    GROUP BY ct.tag_id
),
post_stats AS (
    SELECT
        pt.tag_id,
        COUNT(DISTINCT pt.post_id) AS post_count
    FROM post_has_tag_tag pt
    GROUP BY pt.tag_id
),
comment_like_stats AS (
    SELECT
        ct.tag_id,
        COUNT(*) AS comment_like_count
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
    GROUP BY ct.tag_id
)
SELECT
    t.id AS tag_id,
    t.name AS tag_name,
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(cl.comment_like_count, 0) AS comment_like_count,
    CASE WHEN COALESCE(cs.comment_count, 0) > 0
         THEN COALESCE(cl.comment_like_count, 0) * 1.0 / COALESCE(cs.comment_count, 0)
         ELSE 0
    END AS likes_per_comment
FROM tag t
LEFT JOIN tag_class tc ON t.type_tag_class_id = tc.id
LEFT JOIN comment_stats cs ON t.id = cs.tag_id
LEFT JOIN post_stats ps ON t.id = ps.tag_id
LEFT JOIN comment_like_stats cl ON t.id = cl.tag_id
ORDER BY comment_count DESC
LIMIT 20
