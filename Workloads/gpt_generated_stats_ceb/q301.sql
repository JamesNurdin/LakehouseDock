WITH badge_user AS (
    SELECT
        b.userid,
        b.date AS badge_date,
        u.reputation,
        u.views,
        u.upvotes,
        u.downvotes
    FROM badges b
    JOIN users u ON b.userid = u.id
),
monthly_agg AS (
    SELECT
        date_trunc('month', badge_date) AS month,
        COUNT(*) AS badge_cnt,
        COUNT(DISTINCT userid) AS user_cnt,
        AVG(reputation) AS avg_rep,
        approx_percentile(reputation, 0.5) AS median_rep,
        SUM(views) AS total_views,
        SUM(upvotes) AS total_upvotes,
        SUM(downvotes) AS total_downvotes
    FROM badge_user
    GROUP BY date_trunc('month', badge_date)
)
SELECT
    month,
    badge_cnt,
    user_cnt,
    avg_rep,
    median_rep,
    total_views,
    total_upvotes,
    total_downvotes,
    CASE WHEN total_downvotes = 0 THEN NULL ELSE CAST(total_upvotes AS double) / total_downvotes END AS upvote_downvote_ratio
FROM monthly_agg
ORDER BY month
