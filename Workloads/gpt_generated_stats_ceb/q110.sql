WITH user_badge_counts AS (
    SELECT u.id AS user_id,
           u.reputation,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id, u.reputation
),
user_post_stats AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS post_count,
           AVG(p.score) AS avg_post_score,
           COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_received,
           COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_comment_counts AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_count,
           COUNT(v2.id) AS votes_cast
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    LEFT JOIN votes v2 ON v2.userid = u.id
    GROUP BY u.id
),
user_tag_counts AS (
    SELECT u.id AS user_id,
           COUNT(DISTINCT t.id) AS tag_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT ubc.user_id,
       ubc.reputation,
       ubc.badge_count,
       ups.post_count,
       ups.avg_post_score,
       ups.upvotes_received,
       ups.downvotes_received,
       ucc.comment_count,
       ucc.votes_cast,
       utc.tag_count
FROM user_badge_counts ubc
JOIN user_post_stats ups ON ups.user_id = ubc.user_id
JOIN user_comment_counts ucc ON ucc.user_id = ubc.user_id
JOIN user_tag_counts utc ON utc.user_id = ubc.user_id
WHERE ubc.badge_count >= 3
ORDER BY ups.avg_post_score DESC
LIMIT 5
