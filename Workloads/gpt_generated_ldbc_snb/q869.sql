WITH forum_posts_agg AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(DISTINCT p.id) AS num_posts
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id, f.title
),
forum_comments_agg AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT c.id) AS num_comments,
        AVG(c.length) AS avg_comment_length
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    GROUP BY f.id
),
post_tags AS (
    SELECT
        f.id AS forum_id,
        pt.tag_id,
        t.type_tag_class_id AS tag_class_id
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pt ON pt.post_id = p.id
    JOIN tag t ON t.id = pt.tag_id
),
comment_tags AS (
    SELECT
        f.id AS forum_id,
        ct.tag_id,
        t.type_tag_class_id AS tag_class_id
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
    JOIN tag t ON t.id = ct.tag_id
),
all_tags AS (
    SELECT forum_id, tag_id, tag_class_id FROM post_tags
    UNION ALL
    SELECT forum_id, tag_id, tag_class_id FROM comment_tags
),
forum_tags_agg AS (
    SELECT
        forum_id,
        COUNT(DISTINCT tag_id) AS distinct_tags_used,
        COUNT(DISTINCT tag_class_id) AS distinct_tag_classes_used
    FROM all_tags
    GROUP BY forum_id
)
SELECT
    fpa.forum_id,
    fpa.forum_title,
    fpa.num_posts,
    fca.num_comments,
    fca.avg_comment_length,
    fta.distinct_tags_used,
    fta.distinct_tag_classes_used
FROM forum_posts_agg fpa
LEFT JOIN forum_comments_agg fca ON fca.forum_id = fpa.forum_id
LEFT JOIN forum_tags_agg fta ON fta.forum_id = fpa.forum_id
ORDER BY fca.num_comments DESC
LIMIT 10
