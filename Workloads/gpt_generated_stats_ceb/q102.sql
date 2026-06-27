WITH user_comment_stats AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.views,
        u.upvotes,
        u.downvotes,
        COUNT(c.id) AS comment_count,
        SUM(c.score) AS total_comment_score,
        AVG(c.score) AS avg_comment_score,
        MIN(c.creationdate) AS first_comment_date,
        MAX(c.creationdate) AS last_comment_date
    FROM comments c
    JOIN users u
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
    comment_count,
    total_comment_score,
    avg_comment_score,
    first_comment_date,
    last_comment_date,
    score_rank
FROM (
    SELECT
        user_id,
        reputation,
        comment_count,
        total_comment_score,
        avg_comment_score,
        first_comment_date,
        last_comment_date,
        RANK() OVER (ORDER BY total_comment_score DESC) AS score_rank
    FROM user_comment_stats
) ranked
WHERE score_rank <= 10
ORDER BY total_comment_score DESC
