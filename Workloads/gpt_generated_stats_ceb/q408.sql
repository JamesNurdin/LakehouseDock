WITH user_posthistory AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate AS user_creationdate,
        u.views,
        u.upvotes,
        u.downvotes,
        COUNT(p.id) AS posthistory_count,
        COUNT(DISTINCT p.postid) AS distinct_postids,
        MIN(p.creationdate) AS first_event,
        MAX(p.creationdate) AS last_event,
        date_diff('day', date(min(p.creationdate)), date(max(p.creationdate))) AS active_days
    FROM users u
    LEFT JOIN posthistory p
        ON p.userid = u.id
    GROUP BY
        u.id,
        u.reputation,
        u.creationdate,
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
    posthistory_count,
    distinct_postids,
    first_event,
    last_event,
    active_days,
    RANK() OVER (ORDER BY posthistory_count DESC) AS rank_by_events
FROM user_posthistory
ORDER BY posthistory_count DESC
LIMIT 20
