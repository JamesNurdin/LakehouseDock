WITH user_month AS (
    SELECT
        b.userid,
        date_trunc('month', b.date) AS month,
        COUNT(*) AS badge_count,
        MAX(u.reputation) AS reputation,
        MAX(u.views) AS views,
        MAX(u.upvotes) AS upvotes,
        MAX(u.downvotes) AS downvotes
    FROM badges b
    JOIN users u
      ON b.userid = u.id
    GROUP BY b.userid, date_trunc('month', b.date)
)
SELECT
    month,
    COUNT(*) AS distinct_user_count,
    SUM(badge_count) AS total_badges,
    AVG(reputation) AS avg_user_reputation,
    SUM(views) AS total_views,
    SUM(upvotes) AS total_upvotes,
    SUM(downvotes) AS total_downvotes,
    (SUM(badge_count) * 1.0) / NULLIF(COUNT(*), 0) AS avg_badges_per_user
FROM user_month
GROUP BY month
ORDER BY month DESC
