WITH user_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_score,
        AVG(p.score) AS avg_score,
        SUM(p.answercount) AS total_answer_count,
        SUM(p.commentcount) AS total_comment_count,
        SUM(p.favoritecount) AS total_favorite_count,
        SUM(p.viewcount) AS total_view_count
    FROM posts p
    GROUP BY p.owneruserid
),
user_edits AS (
    SELECT
        p.lasteditoruserid AS user_id,
        COUNT(*) AS edit_count
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
),
user_history AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS history_actions,
        COUNT(DISTINCT ph.posthistorytypeid) AS distinct_history_types
    FROM posthistory ph
    GROUP BY ph.userid
),
user_info AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate,
        u.views,
        u.upvotes,
        u.downvotes
    FROM users u
)
SELECT
    ui.user_id,
    ui.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_score, 0) AS total_score,
    COALESCE(up.avg_score, 0) AS avg_score,
    COALESCE(up.total_answer_count, 0) AS total_answer_count,
    COALESCE(up.total_comment_count, 0) AS total_comment_count,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(up.total_view_count, 0) AS total_view_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(uh.history_actions, 0) AS history_actions,
    COALESCE(uh.distinct_history_types, 0) AS distinct_history_types
FROM user_info ui
LEFT JOIN user_posts up ON ui.user_id = up.user_id
LEFT JOIN user_edits ue ON ui.user_id = ue.user_id
LEFT JOIN user_history uh ON ui.user_id = uh.user_id
ORDER BY ui.reputation DESC
LIMIT 100
