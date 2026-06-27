WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate,
        u.views,
        u.upvotes,
        u.downvotes,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        CASE WHEN COUNT(p.id) > 0 THEN AVG(p.score) END AS avg_post_score
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation, u.creationdate, u.views, u.upvotes, u.downvotes
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count,
        COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count,
        MIN(b.date) AS first_badge_date
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
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS edited_post_count
    FROM users u
    LEFT JOIN posts p
        ON p.lasteditoruserid = u.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.reputation,
    up.creationdate,
    up.views,
    up.upvotes,
    up.downvotes,
    up.post_count,
    up.total_post_score,
    up.avg_post_score,
    uc.comment_count,
    uc.total_comment_score,
    ub.badge_count,
    ub.first_badge_date,
    uph.posthistory_count,
    ue.edited_post_count
FROM user_posts up
LEFT JOIN user_comments uc
    ON uc.user_id = up.user_id
LEFT JOIN user_badges ub
    ON ub.user_id = up.user_id
LEFT JOIN user_posthistory uph
    ON uph.user_id = up.user_id
LEFT JOIN user_edits ue
    ON ue.user_id = up.user_id
ORDER BY up.reputation DESC
LIMIT 100
