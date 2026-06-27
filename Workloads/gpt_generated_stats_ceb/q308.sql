WITH user_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS posts_authored,
        COALESCE(SUM(p.score), 0) AS total_score,
        COALESCE(SUM(p.viewcount), 0) AS total_views,
        COALESCE(SUM(p.answercount), 0) AS total_answers,
        COALESCE(SUM(p.commentcount), 0) AS total_comments,
        COALESCE(SUM(p.favoritecount), 0) AS total_favorites,
        COALESCE(AVG(p.score), 0) AS avg_score
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS posts_edited
    FROM users u
    LEFT JOIN posts p
        ON p.lasteditoruserid = u.id
    GROUP BY u.id
),
user_history AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS posthistory_entries,
        COUNT(p.id) AS posthistory_linked_posts
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    LEFT JOIN posts p
        ON ph.posthistorytypeid = p.id
    GROUP BY u.id
)
SELECT
    u.id,
    u.reputation,
    up.posts_authored,
    up.total_score,
    up.total_views,
    up.total_answers,
    up.total_comments,
    up.total_favorites,
    up.avg_score,
    ue.posts_edited,
    uh.posthistory_entries,
    uh.posthistory_linked_posts
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_history uh ON uh.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 20
