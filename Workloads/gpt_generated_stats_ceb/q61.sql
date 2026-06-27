-- Top 10 users by reputation with activity metrics
WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS post_count,
        SUM(p.score) AS total_score,
        AVG(p.score) AS avg_score,
        SUM(p.viewcount) AS total_views
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_history AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS history_count,
        COUNT(DISTINCT ph.postid) AS distinct_posts_edited
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    GROUP BY u.id
),
user_last_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS last_edit_count
    FROM users u
    LEFT JOIN posts p
        ON p.lasteditoruserid = u.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.reputation,
    up.post_count,
    up.total_score,
    up.avg_score,
    up.total_views,
    uh.history_count,
    uh.distinct_posts_edited,
    ule.last_edit_count
FROM user_posts up
LEFT JOIN user_history uh
    ON up.user_id = uh.user_id
LEFT JOIN user_last_edits ule
    ON up.user_id = ule.user_id
ORDER BY up.reputation DESC
LIMIT 10
