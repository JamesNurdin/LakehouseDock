WITH tag_agg AS (
    SELECT
        tags.id AS tag_id,
        tags.count AS tag_usage,
        SUM(posts.score) AS total_score,
        AVG(posts.viewcount) AS avg_viewcount,
        COUNT(posts.id) AS post_cnt
    FROM tags
    JOIN posts ON tags.excerptpostid = posts.id
    WHERE posts.posttypeid = 1
    GROUP BY tags.id, tags.count
)
SELECT
    tag_id,
    tag_usage,
    total_score,
    avg_viewcount,
    post_cnt,
    ROW_NUMBER() OVER (ORDER BY total_score DESC) AS rank_by_score
FROM tag_agg
WHERE post_cnt >= 5
ORDER BY rank_by_score
LIMIT 10
