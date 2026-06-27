WITH
forum_base AS (
    SELECT 
        f.id AS forum_id,
        f.title AS forum_title,
        f.creation_date AS forum_creation_date
    FROM forum f
),
comment_agg AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT p.id) AS post_count,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN comment c ON c.parent_post_id = p.id
    GROUP BY f.id
),
tag_agg AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN comment c ON c.parent_post_id = p.id
    LEFT JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    LEFT JOIN tag t ON t.id = cht.tag_id
    GROUP BY f.id
),
top_tag_per_forum AS (
    SELECT
        f.id AS forum_id,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(*) AS tag_usage,
        ROW_NUMBER() OVER (PARTITION BY f.id ORDER BY COUNT(*) DESC) AS rn
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    JOIN tag t ON t.id = cht.tag_id
    GROUP BY f.id, t.id, t.name
)
SELECT
    fb.forum_id,
    fb.forum_title,
    fb.forum_creation_date,
    ca.post_count,
    ca.comment_count,
    ca.avg_comment_length,
    ta.distinct_tag_count,
    tt.tag_name AS top_tag,
    tt.tag_usage AS top_tag_usage
FROM forum_base fb
LEFT JOIN comment_agg ca ON ca.forum_id = fb.forum_id
LEFT JOIN tag_agg ta ON ta.forum_id = fb.forum_id
LEFT JOIN (
    SELECT forum_id, tag_name, tag_usage
    FROM top_tag_per_forum
    WHERE rn = 1
) tt ON tt.forum_id = fb.forum_id
ORDER BY ca.comment_count DESC NULLS LAST
LIMIT 10
