WITH user_hist AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.upvotes,
        u.downvotes,
        u.views,
        COUNT(ph.id) AS post_history_count,
        MIN(ph.creationdate) AS first_history,
        MAX(ph.creationdate) AS last_history
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
        AND ph.posthistorytypeid = 2
    GROUP BY u.id, u.reputation, u.upvotes, u.downvotes, u.views
)
SELECT
    CASE
        WHEN reputation < 1000 THEN 'Low'
        WHEN reputation < 10000 THEN 'Medium'
        ELSE 'High'
    END AS reputation_bucket,
    COUNT(user_id) AS user_count,
    SUM(post_history_count) AS total_post_history,
    AVG(post_history_count) AS avg_post_history_per_user,
    AVG(upvotes) AS avg_upvotes,
    AVG(downvotes) AS avg_downvotes,
    AVG(views) AS avg_views,
    MIN(first_history) AS earliest_history_overall,
    MAX(last_history) AS latest_history_overall
FROM user_hist
GROUP BY
    CASE
        WHEN reputation < 1000 THEN 'Low'
        WHEN reputation < 10000 THEN 'Medium'
        ELSE 'High'
    END
ORDER BY reputation_bucket
