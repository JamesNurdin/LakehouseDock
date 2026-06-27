WITH post_metrics AS (
    SELECT
        p.id AS post_id,
        p.owneruserid AS owner_user_id,
        p.score AS post_score,
        p.creationdate AS post_creationdate,
        COUNT(DISTINCT v.id) AS vote_count,
        COUNT(DISTINCT c.id) AS comment_count,
        SUM(COALESCE(v.bountyamount, 0)) AS total_bounty
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    LEFT JOIN comments c ON c.postid = p.id
    GROUP BY p.id, p.owneruserid, p.score, p.creationdate
),
owner_metrics AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(DISTINCT b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id, u.reputation
)
SELECT
    t.id AS tag_id,
    COUNT(DISTINCT p.id) AS post_count,
    AVG(p.score) AS avg_post_score,
    AVG(u.reputation) AS avg_owner_reputation,
    SUM(pm.vote_count) AS total_votes,
    AVG(pm.vote_count) AS avg_votes_per_post,
    SUM(pm.comment_count) AS total_comments,
    AVG(pm.comment_count) AS avg_comments_per_post,
    SUM(pm.total_bounty) AS total_bounty_amount,
    SUM(om.badge_count) AS total_owner_badges
FROM tags t
JOIN posts p ON t.excerptpostid = p.id
JOIN users u ON p.owneruserid = u.id
JOIN post_metrics pm ON pm.post_id = p.id
JOIN owner_metrics om ON om.user_id = u.id
WHERE p.creationdate >= current_timestamp - INTERVAL '1' YEAR
  AND p.posttypeid = 1
GROUP BY t.id
ORDER BY post_count DESC
LIMIT 10
