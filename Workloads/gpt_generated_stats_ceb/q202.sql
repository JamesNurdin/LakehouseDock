WITH user_history_stats AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.views,
        u.upvotes,
        u.downvotes,
        COUNT(ph.id) AS total_history,
        COUNT(DISTINCT ph.postid) AS distinct_posts,
        MIN(ph.creationdate) AS first_history,
        MAX(ph.creationdate) AS last_history,
        DATE_DIFF('day', MIN(ph.creationdate), MAX(ph.creationdate)) AS active_days
    FROM posthistory ph
    JOIN users u
        ON ph.userid = u.id
    WHERE ph.posthistorytypeid = 2
    GROUP BY u.id, u.reputation, u.views, u.upvotes, u.downvotes
)
SELECT
    user_id,
    reputation,
    views,
    upvotes,
    downvotes,
    total_history,
    distinct_posts,
    first_history,
    last_history,
    active_days,
    CASE WHEN total_history > 0 THEN CAST(upvotes AS double) / total_history ELSE NULL END AS upvotes_per_history,
    ROW_NUMBER() OVER (ORDER BY total_history DESC) AS user_rank
FROM user_history_stats
ORDER BY total_history DESC
LIMIT 20
