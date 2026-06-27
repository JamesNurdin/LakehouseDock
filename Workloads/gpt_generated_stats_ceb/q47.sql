WITH tag_post_metrics AS (
    SELECT
        tags.id AS tag_id,
        tags.count AS tag_usage,
        posts.posttypeid,
        COUNT(posts.id) AS post_cnt,
        SUM(posts.score) AS total_score,
        AVG(posts.score) AS avg_score,
        SUM(posts.viewcount) AS total_views,
        MAX(posts.answercount) AS max_answers,
        MIN(posts.creationdate) AS earliest_creation,
        MAX(posts.creationdate) AS latest_creation
    FROM tags
    JOIN posts ON tags.excerptpostid = posts.id
    WHERE tags.count > 100
    GROUP BY tags.id, tags.count, posts.posttypeid
)
SELECT
    tag_id,
    tag_usage,
    posttypeid,
    post_cnt,
    total_score,
    avg_score,
    total_views,
    max_answers,
    earliest_creation,
    latest_creation,
    ROW_NUMBER() OVER (PARTITION BY tag_id ORDER BY total_score DESC) AS rank_by_score
FROM tag_post_metrics
ORDER BY tag_id, rank_by_score
LIMIT 50
