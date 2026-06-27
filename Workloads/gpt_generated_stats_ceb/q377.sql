WITH user_activity AS (
    SELECT
        ph.userid,
        ph.posthistorytypeid,
        ph.postid,
        ph.creationdate,
        u.reputation,
        u.views,
        u.upvotes,
        u.downvotes
    FROM posthistory ph
    JOIN users u ON ph.userid = u.id
)
SELECT
    ua.posthistorytypeid,
    COUNT(*) AS event_count,
    COUNT(DISTINCT ua.userid) AS distinct_user_count,
    AVG(ua.reputation) AS avg_user_reputation,
    SUM(ua.views) AS total_user_views,
    SUM(ua.upvotes) AS total_user_upvotes,
    SUM(ua.downvotes) AS total_user_downvotes,
    MIN(ua.creationdate) AS first_event_timestamp,
    MAX(ua.creationdate) AS last_event_timestamp
FROM user_activity ua
GROUP BY ua.posthistorytypeid
ORDER BY event_count DESC
