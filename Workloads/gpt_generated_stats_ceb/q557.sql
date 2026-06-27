WITH user_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS owned_post_count,
        SUM(p.score) AS owned_post_score_sum,
        AVG(p.viewcount) AS owned_post_viewcount_avg
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS edited_post_count,
        SUM(p.score) AS edited_post_score_sum
    FROM users u
    LEFT JOIN posts p ON p.lasteditoruserid = u.id
    GROUP BY u.id
),
user_tags AS (
    SELECT
        u.id AS user_id,
        COUNT(t.id) AS tag_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_history AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS posthistory_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    LEFT JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY u.id
)
SELECT
    u.id,
    u.reputation,
    COALESCE(up.owned_post_count, 0) AS owned_post_count,
    COALESCE(up.owned_post_score_sum, 0) AS owned_post_score_sum,
    COALESCE(up.owned_post_viewcount_avg, 0) AS owned_post_viewcount_avg,
    COALESCE(ue.edited_post_count, 0) AS edited_post_count,
    COALESCE(ue.edited_post_score_sum, 0) AS edited_post_score_sum,
    COALESCE(ut.tag_count, 0) AS tag_count,
    COALESCE(uh.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
LEFT JOIN user_history uh ON uh.user_id = u.id
WHERE u.reputation > 1000
ORDER BY u.reputation DESC
LIMIT 100
