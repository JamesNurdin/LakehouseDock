WITH user_posts AS (
    SELECT
        owneruserid,
        COUNT(*) AS post_count,
        COALESCE(SUM(score), 0) AS total_post_score,
        COALESCE(SUM(viewcount), 0) AS total_viewcount
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid,
        COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT
        userid,
        COUNT(*) AS vote_cast_count
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_edits AS (
    SELECT
        userid,
        COUNT(*) AS edit_count
    FROM posthistory
    GROUP BY userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.total_viewcount, 0) AS total_viewcount,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(v.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(e.edit_count, 0) AS edit_count,
    (u.reputation
        + COALESCE(p.post_count, 0) * 10
        + COALESCE(c.comment_count, 0) * 2
        + COALESCE(b.badge_count, 0) * 5
        + COALESCE(v.vote_cast_count, 0)
        + COALESCE(e.edit_count, 0) * 3
    ) AS activity_score
FROM users u
LEFT JOIN user_posts p ON p.owneruserid = u.id
LEFT JOIN user_comments c ON c.userid = u.id
LEFT JOIN user_votes v ON v.userid = u.id
LEFT JOIN user_badges b ON b.userid = u.id
LEFT JOIN user_edits e ON e.userid = u.id
ORDER BY activity_score DESC
LIMIT 10
