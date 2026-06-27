WITH user_activity AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(DISTINCT p.id) AS posts_owned,
        COUNT(DISTINCT le.id) AS posts_edited,
        COALESCE(SUM(p.viewcount), 0) AS total_viewcount,
        COALESCE(SUM(p.score), 0) AS total_score,
        COUNT(DISTINCT c.id) AS comments_made,
        COUNT(DISTINCT v.id) AS votes_cast,
        COUNT(DISTINCT b.id) AS badges_earned,
        COUNT(DISTINCT ph.id) AS posthistory_actions,
        COUNT(DISTINCT t.id) AS tags_on_owned_posts,
        COUNT(DISTINCT pl.id) AS postlinks_owned
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN posts le ON le.lasteditoruserid = u.id
    LEFT JOIN comments c ON c.userid = u.id
    LEFT JOIN votes v ON v.userid = u.id
    LEFT JOIN badges b ON b.userid = u.id
    LEFT JOIN posthistory ph ON ph.userid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY u.id, u.reputation
)
SELECT *
FROM user_activity
ORDER BY total_score DESC
LIMIT 10
