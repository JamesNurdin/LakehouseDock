WITH user_badge_counts AS (
    SELECT u.id AS user_id,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_post_counts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS post_count,
           SUM(p.score) AS total_post_score,
           AVG(p.score) AS avg_post_score
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_edit_counts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS edited_posts_count
    FROM users u
    LEFT JOIN posts p ON p.lasteditoruserid = u.id
    GROUP BY u.id
),
user_history_counts AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS posthistory_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
),
user_history_posttype_metrics AS (
    SELECT u.id AS user_id,
           COUNT(DISTINCT p.id) AS distinct_posttype_post_count,
           COALESCE(SUM(p.score), 0) AS sum_posttype_post_score
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    LEFT JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY u.id
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(ubc.badge_count, 0) AS badge_count,
       COALESCE(upc.post_count, 0) AS post_count,
       COALESCE(upc.total_post_score, 0) AS total_post_score,
       COALESCE(upc.avg_post_score, 0) AS avg_post_score,
       COALESCE(uec.edited_posts_count, 0) AS edited_posts_count,
       COALESCE(uhc.posthistory_count, 0) AS posthistory_count,
       COALESCE(uhpm.distinct_posttype_post_count, 0) AS distinct_posttype_post_count,
       COALESCE(uhpm.sum_posttype_post_score, 0) AS sum_posttype_post_score,
       COALESCE(ubc.badge_count, 0) * 10 AS badge_points
FROM users u
LEFT JOIN user_badge_counts ubc ON ubc.user_id = u.id
LEFT JOIN user_post_counts upc ON upc.user_id = u.id
LEFT JOIN user_edit_counts uec ON uec.user_id = u.id
LEFT JOIN user_history_counts uhc ON uhc.user_id = u.id
LEFT JOIN user_history_posttype_metrics uhpm ON uhpm.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 10
