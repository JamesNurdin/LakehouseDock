/*
  Analytical query: forum‑level activity with the most used tag per forum.
  The query aggregates the number of posts, comments, average comment length,
  distinct tags used in comments, and returns the top tag (by usage) for each forum.
  Results are ordered by the total number of comments descending and limited to the
  top 20 forums.
*/
WITH post_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT p.id) AS num_posts
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    GROUP BY f.id
),
comment_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT c.id) AS num_comments,
        AVG(c.length) AS avg_comment_length
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    GROUP BY f.id
),
tag_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT cht.tag_id) AS distinct_tag_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN comment_has_tag_tag cht
        ON cht.comment_id = c.id
    GROUP BY f.id
),
comment_tag_counts AS (
    SELECT
        f.id AS forum_id,
        cht.tag_id,
        COUNT(*) AS tag_usage
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN comment_has_tag_tag cht
        ON cht.comment_id = c.id
    WHERE cht.tag_id IS NOT NULL
    GROUP BY f.id, cht.tag_id
),
top_tag_per_forum AS (
    SELECT
        forum_id,
        tag_id,
        tag_usage,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_usage DESC) AS rn
    FROM comment_tag_counts
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(ps.num_posts, 0) AS num_posts,
    COALESCE(cs.num_comments, 0) AS num_comments,
    cs.avg_comment_length,
    COALESCE(ts.distinct_tag_count, 0) AS distinct_tag_count,
    ttf.tag_id AS top_tag_id,
    ttf.tag_usage AS top_tag_usage
FROM forum f
LEFT JOIN post_stats ps
    ON ps.forum_id = f.id
LEFT JOIN comment_stats cs
    ON cs.forum_id = f.id
LEFT JOIN tag_stats ts
    ON ts.forum_id = f.id
LEFT JOIN (
    SELECT forum_id, tag_id, tag_usage
    FROM top_tag_per_forum
    WHERE rn = 1
) ttf
    ON ttf.forum_id = f.id
ORDER BY num_comments DESC
LIMIT 20
