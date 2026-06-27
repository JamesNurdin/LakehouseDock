WITH
    user_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS posts_owned,
            SUM(p.score) AS total_score,
            AVG(p.score) AS avg_score,
            SUM(p.viewcount) AS total_views_posts,
            SUM(p.favoritecount) AS total_favorites
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_edits AS (
        SELECT
            p.lasteditoruserid AS user_id,
            COUNT(*) AS posts_edited
        FROM posts p
        WHERE p.lasteditoruserid IS NOT NULL
        GROUP BY p.lasteditoruserid
    ),
    user_history AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS history_actions,
            COUNT(DISTINCT ph.postid) AS distinct_posts_in_history
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    users_base AS (
        SELECT
            u.id AS user_id,
            u.reputation,
            u.creationdate,
            u.views AS user_views,
            u.upvotes,
            u.downvotes
        FROM users u
    )
SELECT
    ub.user_id,
    ub.reputation,
    ub.creationdate,
    ub.user_views,
    ub.upvotes,
    ub.downvotes,
    COALESCE(up.posts_owned, 0) AS posts_owned,
    COALESCE(up.total_score, 0) AS total_score_owned_posts,
    COALESCE(up.avg_score, 0) AS avg_score_owned_posts,
    COALESCE(up.total_views_posts, 0) AS total_views_owned_posts,
    COALESCE(up.total_favorites, 0) AS total_favorites_owned_posts,
    COALESCE(ue.posts_edited, 0) AS posts_edited,
    COALESCE(uh.history_actions, 0) AS history_actions,
    COALESCE(uh.distinct_posts_in_history, 0) AS distinct_posts_acted_on,
    (COALESCE(up.posts_owned, 0) * 2
     + COALESCE(ue.posts_edited, 0) * 1
     + COALESCE(uh.history_actions, 0) * 0.5) AS activity_score
FROM users_base ub
LEFT JOIN user_posts up ON ub.user_id = up.user_id
LEFT JOIN user_edits ue ON ub.user_id = ue.user_id
LEFT JOIN user_history uh ON ub.user_id = uh.user_id
ORDER BY activity_score DESC, ub.reputation DESC
LIMIT 20
