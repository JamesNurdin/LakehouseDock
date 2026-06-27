WITH user_activity AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(DISTINCT p.id) AS post_count,
        COALESCE(SUM(p.viewcount), 0) AS total_views,
        COALESCE(AVG(p.score), 0) AS avg_post_score,
        COUNT(DISTINCT c.id) AS comment_count,
        COUNT(DISTINCT v.id) AS vote_cast_count,
        COUNT(DISTINCT b.id) AS badge_count,
        COUNT(DISTINCT ph.id) AS edit_count,
        COUNT(DISTINCT pl.id) AS postlink_count,
        COUNT(DISTINCT t.id) AS tag_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN comments c ON c.userid = u.id
    LEFT JOIN votes v ON v.userid = u.id
    LEFT JOIN badges b ON b.userid = u.id
    LEFT JOIN posthistory ph ON ph.userid = u.id
    LEFT JOIN postlinks pl ON pl.postid = p.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id, u.reputation
)
SELECT *
FROM user_activity
ORDER BY total_views DESC
LIMIT 20
