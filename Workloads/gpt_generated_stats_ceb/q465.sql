WITH user_comment_stats AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.views,
        u.upvotes,
        u.downvotes,
        COUNT(c.id) AS comment_count,
        AVG(c.score) AS avg_comment_score,
        SUM(c.score) AS total_comment_score,
        MAX(c.creationdate) AS last_comment_date
    FROM comments c
    JOIN users u ON c.userid = u.id
    GROUP BY u.id, u.reputation, u.views, u.upvotes, u.downvotes
    HAVING COUNT(c.id) >= 10
)
SELECT
    user_id,
    reputation,
    views,
    upvotes,
    downvotes,
    comment_count,
    avg_comment_score,
    total_comment_score,
    last_comment_date,
    (upvotes + downvotes) * avg_comment_score AS engagement_score,
    ROW_NUMBER() OVER (ORDER BY (upvotes + downvotes) * avg_comment_score DESC) AS engagement_rank
FROM user_comment_stats
ORDER BY engagement_score DESC
LIMIT 20
