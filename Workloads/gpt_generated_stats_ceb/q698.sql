-- Analytical query: activity of users per post‑history type with reputation ranking
WITH user_activity AS (
    SELECT
        ph.userid,
        ph.posthistorytypeid,
        COUNT(*) AS event_count,
        COUNT(DISTINCT ph.postid) AS distinct_posts,
        MIN(ph.creationdate) AS first_event,
        MAX(ph.creationdate) AS last_event
    FROM posthistory AS ph
    GROUP BY ph.userid, ph.posthistorytypeid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.views,
    u.upvotes,
    u.downvotes,
    ua.posthistorytypeid,
    ua.event_count,
    ua.distinct_posts,
    date_diff('day', u.creationdate, ua.last_event) AS days_from_join_to_last_event,
    RANK() OVER (ORDER BY u.reputation DESC) AS reputation_rank
FROM users AS u
JOIN user_activity AS ua
    ON ua.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
