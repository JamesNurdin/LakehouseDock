WITH badge_user AS (
    SELECT
        b.userid AS user_id,
        date_trunc('month', b.date) AS badge_month,
        date_diff('day', u.creationdate, b.date) AS days_since_creation,
        u.reputation,
        u.upvotes,
        u.downvotes
    FROM badges b
    JOIN users u
        ON b.userid = u.id
    WHERE u.reputation >= 1000
)
SELECT
    badge_month,
    COUNT(DISTINCT user_id) AS distinct_users,
    COUNT(*) AS total_badges,
    AVG(reputation) AS avg_user_reputation,
    SUM(upvotes) AS total_upvotes,
    SUM(downvotes) AS total_downvotes,
    AVG(days_since_creation) AS avg_days_since_creation
FROM badge_user
GROUP BY badge_month
ORDER BY badge_month
