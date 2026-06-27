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
        MIN(c.creationdate) AS first_comment_date,
        MAX(c.creationdate) AS last_comment_date
    FROM
        users u
    JOIN
        comments c
        ON c.userid = u.id
    GROUP BY
        u.id,
        u.reputation,
        u.views,
        u.upvotes,
        u.downvotes
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
    first_comment_date,
    last_comment_date,
    total_comment_score / NULLIF(views, 0) AS comment_score_per_view,
    RANK() OVER (ORDER BY avg_comment_score DESC) AS avg_score_rank
FROM
    user_comment_stats
WHERE
    comment_count >= 10
ORDER BY
    avg_comment_score DESC
LIMIT 100
