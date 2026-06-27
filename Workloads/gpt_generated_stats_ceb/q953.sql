WITH monthly_badge_stats AS (
    SELECT
        date_trunc('month', b.date) AS badge_month,
        COUNT(b.id) AS badges_awarded,
        COUNT(DISTINCT b.userid) AS distinct_users,
        AVG(u.reputation) AS avg_user_reputation,
        SUM(u.views) AS total_user_views,
        SUM(u.upvotes) AS total_user_upvotes,
        SUM(u.downvotes) AS total_user_downvotes
    FROM badges b
    JOIN users u ON b.userid = u.id
    GROUP BY date_trunc('month', b.date)
)
SELECT
    badge_month,
    badges_awarded,
    distinct_users,
    avg_user_reputation,
    total_user_views,
    total_user_upvotes,
    total_user_downvotes,
    RANK() OVER (ORDER BY badges_awarded DESC) AS month_rank_by_badges
FROM monthly_badge_stats
ORDER BY badge_month DESC
