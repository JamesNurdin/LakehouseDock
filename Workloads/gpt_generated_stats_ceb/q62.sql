WITH user_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS post_count,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_post_views,
        SUM(p.favoritecount) AS total_favorite_count,
        SUM(p.answercount) AS total_answer_count,
        SUM(p.commentcount) AS total_comment_on_posts
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count,
        SUM(c.score) AS comment_score_sum
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
user_posthistory AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS posthistory_count
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    GROUP BY u.id
),
user_edit_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS edited_post_count
    FROM users u
    LEFT JOIN posts p
        ON p.lasteditoruserid = u.id
    GROUP BY u.id
)
SELECT
    u.id,
    u.reputation,
    COALESCE(up.post_count, 0)               AS post_count,
    COALESCE(up.total_post_score, 0)         AS total_post_score,
    COALESCE(up.avg_post_score, 0)           AS avg_post_score,
    COALESCE(up.total_post_views, 0)         AS total_post_views,
    COALESCE(up.total_favorite_count, 0)    AS total_favorite_count,
    COALESCE(up.total_answer_count, 0)      AS total_answer_count,
    COALESCE(up.total_comment_on_posts, 0)  AS total_comment_on_posts,
    COALESCE(uc.comment_count, 0)            AS comment_count,
    COALESCE(uc.comment_score_sum, 0)        AS comment_score_sum,
    COALESCE(ub.badge_count, 0)              AS badge_count,
    COALESCE(uph.posthistory_count, 0)      AS posthistory_count,
    COALESCE(ue.edited_post_count, 0)        AS edited_post_count
FROM users u
LEFT JOIN user_posts up          ON up.user_id = u.id
LEFT JOIN user_comments uc       ON uc.user_id = u.id
LEFT JOIN user_badges ub         ON ub.user_id = u.id
LEFT JOIN user_posthistory uph   ON uph.user_id = u.id
LEFT JOIN user_edit_posts ue     ON ue.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 10
