WITH user_post_votes AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(v.id) AS total_votes_received
    FROM posts p
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_post_comments AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(c.id) AS total_comments_received
    FROM posts p
    LEFT JOIN comments c
        ON c.postid = p.id
    GROUP BY p.owneruserid
),
user_post_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(p.id) AS total_posts,
        AVG(p.score) AS avg_post_score
    FROM posts p
    GROUP BY p.owneruserid
),
user_badge_counts AS (
    SELECT
        b.userid AS user_id,
        COUNT(b.id) AS badge_count
    FROM badges b
    GROUP BY b.userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(pv.total_votes_received, 0) AS total_votes_received,
    COALESCE(pc.total_comments_received, 0) AS total_comments_received,
    COALESCE(ps.total_posts, 0) AS total_posts,
    COALESCE(ps.avg_post_score, 0) AS avg_post_score,
    COALESCE(bc.badge_count, 0) AS badge_count
FROM users u
LEFT JOIN user_post_votes pv
    ON pv.user_id = u.id
LEFT JOIN user_post_comments pc
    ON pc.user_id = u.id
LEFT JOIN user_post_stats ps
    ON ps.user_id = u.id
LEFT JOIN user_badge_counts bc
    ON bc.user_id = u.id
ORDER BY total_votes_received DESC
LIMIT 10
