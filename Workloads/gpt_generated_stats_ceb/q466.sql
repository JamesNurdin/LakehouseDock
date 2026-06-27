WITH post_user AS (
    SELECT 
        date_trunc('month', ph.creationdate) AS month,
        ph.posthistorytypeid,
        ph.postid,
        u.reputation,
        u.views,
        u.upvotes,
        u.downvotes
    FROM posthistory ph
    JOIN users u ON ph.userid = u.id
),
agg AS (
    SELECT 
        month,
        posthistorytypeid,
        count(*) AS total_actions,
        count(DISTINCT postid) AS distinct_posts,
        avg(reputation) AS avg_user_reputation,
        sum(views) AS total_user_views,
        sum(upvotes) AS total_user_upvotes,
        sum(downvotes) AS total_user_downvotes
    FROM post_user
    GROUP BY month, posthistorytypeid
)
SELECT 
    month,
    posthistorytypeid,
    total_actions,
    distinct_posts,
    avg_user_reputation,
    total_user_views,
    total_user_upvotes,
    total_user_downvotes,
    rank() OVER (PARTITION BY month ORDER BY total_actions DESC) AS rank_in_month
FROM agg
WHERE total_actions > 10
ORDER BY month DESC, rank_in_month
LIMIT 50
