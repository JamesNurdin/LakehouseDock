WITH user_comment_stats AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.views,
        u.upvotes,
        u.downvotes,
        COUNT(c.id) AS comment_count,
        AVG(c.score) AS avg_comment_score,
        approx_percentile(c.score, 0.5) AS median_comment_score,
        SUM(c.score) AS total_comment_score,
        MAX(c.creationdate) AS last_comment_date
    FROM comments c
    JOIN users u ON c.userid = u.id
    GROUP BY u.id, u.reputation, u.views, u.upvotes, u.downvotes
)
SELECT
    user_id,
    reputation,
    views,
    upvotes,
    downvotes,
    comment_count,
    avg_comment_score,
    median_comment_score,
    total_comment_score,
    last_comment_date,
    PERCENT_RANK() OVER (ORDER BY total_comment_score DESC) AS total_score_percentile,
    ROW_NUMBER() OVER (ORDER BY comment_count DESC) AS comment_count_rank
FROM user_comment_stats
ORDER BY total_comment_score DESC
LIMIT 100
