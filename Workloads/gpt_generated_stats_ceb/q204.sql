WITH user_activity AS (
    SELECT 
        u.id AS user_id,
        u.reputation,
        COUNT(ph.id) AS posthistory_actions,
        COUNT(DISTINCT p.id) AS distinct_posts,
        SUM(CASE WHEN p.owneruserid = u.id THEN p.score ELSE 0 END) AS owned_score_sum,
        SUM(CASE WHEN p.lasteditoruserid = u.id THEN p.score ELSE 0 END) AS edited_score_sum,
        SUM(p.viewcount) AS total_viewcount,
        MIN(p.creationdate) AS earliest_post_date,
        MAX(p.creationdate) AS latest_post_date
    FROM posthistory ph
    JOIN users u ON ph.userid = u.id
    LEFT JOIN posts p ON ph.posthistorytypeid = p.id
    WHERE u.reputation >= 2000
    GROUP BY u.id, u.reputation
)
SELECT 
    user_id,
    reputation,
    posthistory_actions,
    distinct_posts,
    owned_score_sum,
    edited_score_sum,
    total_viewcount,
    earliest_post_date,
    latest_post_date,
    ROW_NUMBER() OVER (ORDER BY posthistory_actions DESC) AS rank_by_history
FROM user_activity
ORDER BY posthistory_actions DESC
LIMIT 20
