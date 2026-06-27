WITH user_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(score) AS total_score,
        AVG(score) AS avg_score
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS comment_received
    FROM posts p
    JOIN comments c ON c.postid = p.id
    GROUP BY p.owneruserid
),
user_votes AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS vote_received
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_edits AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS edit_count
    FROM posts p
    JOIN posthistory ph ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_score, 0) AS total_score,
    COALESCE(up.avg_score, 0) AS avg_score,
    COALESCE(uc.comment_received, 0) AS comment_received,
    COALESCE(uv.vote_received, 0) AS vote_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.edit_count, 0) AS edit_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes uv ON uv.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
WHERE u.reputation > 1000
ORDER BY u.reputation DESC
LIMIT 10
