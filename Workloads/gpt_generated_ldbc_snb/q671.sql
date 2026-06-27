WITH post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
post_tag_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT pt.tag_id) AS distinct_post_tag_count,
        COUNT(DISTINCT t.type_tag_class_id) AS distinct_post_tag_class_count
    FROM post p
    LEFT JOIN post_has_tag_tag pt ON pt.post_id = p.id
    LEFT JOIN tag t ON t.id = pt.tag_id
    GROUP BY p.container_forum_id
),
comment_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
comment_tag_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT ct.tag_id) AS distinct_comment_tag_count,
        COUNT(DISTINCT t.type_tag_class_id) AS distinct_comment_tag_class_count
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    LEFT JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
    LEFT JOIN tag t ON t.id = ct.tag_id
    GROUP BY p.container_forum_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    f.creation_date AS forum_creation_date,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(pt.distinct_post_tag_count, 0) AS distinct_post_tag_count,
    COALESCE(pt.distinct_post_tag_class_count, 0) AS distinct_post_tag_class_count,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(ct.distinct_comment_tag_count, 0) AS distinct_comment_tag_count,
    COALESCE(ct.distinct_comment_tag_class_count, 0) AS distinct_comment_tag_class_count
FROM forum f
LEFT JOIN post_stats ps ON ps.forum_id = f.id
LEFT JOIN post_tag_stats pt ON pt.forum_id = f.id
LEFT JOIN comment_stats cs ON cs.forum_id = f.id
LEFT JOIN comment_tag_stats ct ON ct.forum_id = f.id
ORDER BY post_count DESC
LIMIT 10
