WITH user_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS post_count,
        SUM(p.viewcount) AS total_views,
        SUM(p.answercount) AS total_answers,
        SUM(p.favoritecount) AS total_favorites,
        SUM(p.score) AS total_post_score
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS edited_post_count
    FROM users u
    LEFT JOIN posts p
        ON p.lasteditoruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count,
        AVG(c.score) AS avg_comment_score,
        SUM(c.score) AS total_comment_score
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
),
user_history AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS post_history_count
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    GROUP BY u.id
),
user_owned_history AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS owned_post_history_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN posthistory ph
        ON ph.posthistorytypeid = p.id
    GROUP BY u.id
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(ue.edited_post_count, 0) AS edited_post_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uh.post_history_count, 0) AS post_history_count,
    COALESCE(uoh.owned_post_history_count, 0) AS owned_post_history_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_history uh ON uh.user_id = u.id
LEFT JOIN user_owned_history uoh ON uoh.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
