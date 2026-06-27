WITH tag_agg AS (
    SELECT
        tags.id AS tag_id,
        tags.count AS tag_use_count,
        COUNT(*) AS excerpt_post_count,
        AVG(posts.score) AS avg_score,
        SUM(posts.viewcount) AS total_views,
        AVG(posts.answercount) AS avg_answers
    FROM tags
    JOIN posts ON tags.excerptpostid = posts.id
    GROUP BY tags.id, tags.count
)
SELECT
    tag_id,
    tag_use_count,
    excerpt_post_count,
    avg_score,
    total_views,
    avg_answers,
    PERCENT_RANK() OVER (ORDER BY total_views) AS view_percentile
FROM tag_agg
ORDER BY total_views DESC
LIMIT 20
