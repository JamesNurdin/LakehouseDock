WITH badge_counts AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
comment_stats AS (
    SELECT userid,
           COUNT(*) AS comment_count,
           SUM(score) AS comment_score
    FROM comments
    GROUP BY userid
),
owner_post_stats AS (
    SELECT owneruserid AS userid,
           COUNT(*) AS owned_post_count,
           SUM(score) AS owned_post_score
    FROM posts
    GROUP BY owneruserid
),
editor_post_stats AS (
    SELECT lasteditoruserid AS userid,
           COUNT(*) AS edited_post_count,
           AVG(score) AS edited_post_avg_score
    FROM posts
    GROUP BY lasteditoruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.comment_score, 0) AS comment_score,
    COALESCE(op.owned_post_count, 0) AS owned_post_count,
    COALESCE(op.owned_post_score, 0) AS owned_post_score,
    COALESCE(ep.edited_post_count, 0) AS edited_post_count,
    COALESCE(ep.edited_post_avg_score, 0) AS edited_post_avg_score,
    (COALESCE(bc.badge_count, 0) + COALESCE(cs.comment_count, 0) + COALESCE(op.owned_post_count, 0) + COALESCE(ep.edited_post_count, 0)) AS total_activity,
    ROW_NUMBER() OVER (
        ORDER BY (COALESCE(bc.badge_count, 0) + COALESCE(cs.comment_count, 0) + COALESCE(op.owned_post_count, 0) + COALESCE(ep.edited_post_count, 0)) DESC
    ) AS activity_rank
FROM users u
LEFT JOIN badge_counts bc ON bc.userid = u.id
LEFT JOIN comment_stats cs ON cs.userid = u.id
LEFT JOIN owner_post_stats op ON op.userid = u.id
LEFT JOIN editor_post_stats ep ON ep.userid = u.id
WHERE u.reputation >= 1000
ORDER BY total_activity DESC
LIMIT 100
