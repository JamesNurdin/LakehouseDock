WITH user_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS post_count,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_viewcount
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS vote_count
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_histories AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS history_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS edited_post_count
    FROM users u
    LEFT JOIN posts p ON p.lasteditoruserid = u.id
    GROUP BY u.id
)
SELECT
    u.id,
    u.reputation,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(p.total_viewcount, 0) AS total_viewcount,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(h.history_count, 0) AS history_count,
    COALESCE(e.edited_post_count, 0) AS edited_post_count,
    (COALESCE(p.post_count, 0) +
     COALESCE(c.comment_count, 0) +
     COALESCE(v.vote_count, 0) +
     COALESCE(b.badge_count, 0) +
     COALESCE(h.history_count, 0) +
     COALESCE(e.edited_post_count, 0)) AS total_activity
FROM users u
LEFT JOIN user_posts p ON p.user_id = u.id
LEFT JOIN user_comments c ON c.user_id = u.id
LEFT JOIN user_votes v ON v.user_id = u.id
LEFT JOIN user_badges b ON b.user_id = u.id
LEFT JOIN user_histories h ON h.user_id = u.id
LEFT JOIN user_edits e ON e.user_id = u.id
ORDER BY total_activity DESC
LIMIT 10
