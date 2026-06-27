-- Per‑user activity summary across posts, edits, comments and badges
WITH user_post_stats AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS owned_post_count,
        SUM(p.score) AS owned_post_score_sum,
        AVG(p.score) AS owned_post_score_avg
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_edit_stats AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS edited_post_count
    FROM users u
    LEFT JOIN posts p
        ON p.lasteditoruserid = u.id
    GROUP BY u.id
),
user_comment_stats AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count,
        SUM(c.score) AS comment_score_sum,
        COUNT(DISTINCT c.postid) AS distinct_commented_posts
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_badge_stats AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.owned_post_count, 0)            AS owned_post_count,
    COALESCE(up.owned_post_score_sum, 0)       AS owned_post_score_sum,
    COALESCE(up.owned_post_score_avg, 0)       AS owned_post_score_avg,
    COALESCE(ue.edited_post_count, 0)          AS edited_post_count,
    COALESCE(uc.comment_count, 0)              AS comment_count,
    COALESCE(uc.comment_score_sum, 0)          AS comment_score_sum,
    COALESCE(uc.distinct_commented_posts, 0)  AS distinct_commented_posts,
    COALESCE(ub.badge_count, 0)                AS badge_count
FROM users u
LEFT JOIN user_post_stats   up ON up.user_id = u.id
LEFT JOIN user_edit_stats   ue ON ue.user_id = u.id
LEFT JOIN user_comment_stats uc ON uc.user_id = u.id
LEFT JOIN user_badge_stats  ub ON ub.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
