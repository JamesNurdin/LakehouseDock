WITH user_badge AS (
    SELECT
        b.id AS badge_id,
        b.userid,
        b.date AS badge_date,
        u.reputation,
        u.creationdate,
        u.views,
        u.upvotes,
        u.downvotes
    FROM badges b
    JOIN users u
        ON b.userid = u.id
),
monthly_stats AS (
    SELECT
        DATE_TRUNC('month', badge_date) AS month,
        COUNT(badge_id) AS badges_awarded,
        COUNT(DISTINCT userid) AS distinct_users,
        AVG(reputation) AS avg_user_reputation,
        AVG(DATE_DIFF('day', creationdate, badge_date)) AS avg_days_to_badge,
        SUM(views) AS total_user_views,
        SUM(upvotes) AS total_user_upvotes,
        SUM(downvotes) AS total_user_downvotes
    FROM user_badge
    GROUP BY DATE_TRUNC('month', badge_date)
)
SELECT
    month,
    badges_awarded,
    distinct_users,
    avg_user_reputation,
    avg_days_to_badge,
    total_user_views,
    total_user_upvotes,
    total_user_downvotes
FROM monthly_stats
ORDER BY month DESC
