WITH user_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(score) AS total_score,
        SUM(viewcount) AS total_views
    FROM posts
    GROUP BY owneruserid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
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
        userid AS user_id,
        COUNT(*) AS edit_count
    FROM posthistory
    GROUP BY userid
),
user_last_edits AS (
    SELECT
        lasteditoruserid AS user_id,
        COUNT(*) AS last_edit_posts
    FROM posts
    GROUP BY lasteditoruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_score, 0) AS total_score,
    CASE WHEN COALESCE(p.post_count, 0) > 0 THEN COALESCE(p.total_score, 0) / COALESCE(p.post_count, 0) END AS avg_score_per_post,
    COALESCE(v.votes_received, 0) AS votes_received,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(le.last_edit_posts, 0) AS last_edit_posts
FROM users u
LEFT JOIN user_posts p ON u.id = p.user_id
LEFT JOIN user_votes_received v ON u.id = v.user_id
LEFT JOIN user_badges b ON u.id = b.user_id
LEFT JOIN user_edits e ON u.id = e.user_id
LEFT JOIN user_last_edits le ON u.id = le.user_id
ORDER BY u.reputation DESC
LIMIT 100
