WITH user_activity AS (
    SELECT
        ph.userid,
        COUNT(*) AS event_count,
        COUNT(DISTINCT ph.postid) AS distinct_posts,
        MIN(ph.creationdate) AS first_event_ts,
        MAX(ph.creationdate) AS last_event_ts
    FROM posthistory ph
    GROUP BY ph.userid
),
user_stats AS (
    SELECT
        u.id,
        u.reputation,
        u.views,
        u.upvotes,
        u.downvotes,
        ua.event_count,
        ua.distinct_posts,
        DATE_DIFF('day', ua.first_event_ts, ua.last_event_ts) AS active_days
    FROM users u
    JOIN user_activity ua
        ON u.id = ua.userid
)
SELECT
    id,
    reputation,
    views,
    upvotes,
    downvotes,
    event_count,
    distinct_posts,
    active_days,
    (event_count * 1.0) / NULLIF(active_days, 0) AS events_per_day
FROM user_stats
WHERE event_count >= 10
ORDER BY events_per_day DESC
LIMIT 20
