WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS owned_posts,
        COALESCE(SUM(p.score), 0) AS total_score,
        COALESCE(AVG(p.score), 0) AS avg_score,
        COALESCE(SUM(p.viewcount), 0) AS total_views,
        COALESCE(SUM(p.answercount), 0) AS total_answers,
        COALESCE(SUM(p.commentcount), 0) AS total_comments
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS edited_posts,
        COALESCE(SUM(p.score), 0) AS edited_posts_score
    FROM users u
    LEFT JOIN posts p
        ON p.lasteditoruserid = u.id
    GROUP BY u.id
),
user_history AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS history_entries,
        COUNT(DISTINCT ph.posthistorytypeid) AS distinct_history_types
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.reputation,
    up.owned_posts,
    up.total_score,
    up.avg_score,
    up.total_views,
    up.total_answers,
    up.total_comments,
    ue.edited_posts,
    ue.edited_posts_score,
    uh.history_entries,
    uh.distinct_history_types
FROM user_posts up
LEFT JOIN user_edits ue
    ON ue.user_id = up.user_id
LEFT JOIN user_history uh
    ON uh.user_id = up.user_id
ORDER BY up.total_score DESC
LIMIT 10
