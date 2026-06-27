WITH user_base AS (
    SELECT id, reputation
    FROM users
),
post_metrics AS (
    SELECT owneruserid, COUNT(*) AS post_count, AVG(score) AS avg_post_score
    FROM posts
    GROUP BY owneruserid
),
comment_metrics AS (
    SELECT userid, COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
vote_metrics AS (
    SELECT userid, COUNT(*) AS vote_count
    FROM votes
    GROUP BY userid
),
badge_metrics AS (
    SELECT userid, COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
edit_metrics AS (
    SELECT lasteditoruserid, COUNT(*) AS edit_count
    FROM posts
    GROUP BY lasteditoruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(e.edit_count, 0) AS edit_count,
    (COALESCE(p.post_count, 0) + COALESCE(c.comment_count, 0) + COALESCE(v.vote_count, 0) + COALESCE(b.badge_count, 0) + COALESCE(e.edit_count, 0)) AS total_activity
FROM user_base u
LEFT JOIN post_metrics p ON p.owneruserid = u.id
LEFT JOIN comment_metrics c ON c.userid = u.id
LEFT JOIN vote_metrics v ON v.userid = u.id
LEFT JOIN badge_metrics b ON b.userid = u.id
LEFT JOIN edit_metrics e ON e.lasteditoruserid = u.id
ORDER BY total_activity DESC
LIMIT 100
