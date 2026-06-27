WITH user_badges AS (
    SELECT u.id AS user_id,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_posts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS post_count,
           COALESCE(SUM(p.score), 0) AS total_post_score,
           COALESCE(AVG(p.score), 0) AS avg_post_score,
           COALESCE(SUM(p.viewcount), 0) AS total_post_views
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments_made AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_made_count
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_cast_count
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_posts_received_comments AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_received_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN comments c ON c.postid = p.id
    GROUP BY u.id
),
user_posts_received_votes AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_received_count,
           COALESCE(SUM(v.bountyamount), 0) AS total_bounty_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_posts_tags AS (
    SELECT u.id AS user_id,
           COUNT(t.id) AS tag_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT u.id,
       u.reputation,
       COALESCE(b.badge_count, 0)          AS badge_count,
       COALESCE(p.post_count, 0)           AS post_count,
       COALESCE(p.total_post_score, 0)    AS total_post_score,
       COALESCE(p.avg_post_score, 0)      AS avg_post_score,
       COALESCE(p.total_post_views, 0)    AS total_post_views,
       COALESCE(cm.comment_made_count, 0) AS comment_made_count,
       COALESCE(cr.comment_received_count, 0) AS comment_received_count,
       COALESCE(vc.votes_cast_count, 0)   AS votes_cast_count,
       COALESCE(vr.votes_received_count, 0) AS votes_received_count,
       COALESCE(vr.total_bounty_received, 0) AS total_bounty_received,
       COALESCE(t.tag_count, 0)           AS tag_count
FROM users u
LEFT JOIN user_badges b               ON b.user_id = u.id
LEFT JOIN user_posts p                ON p.user_id = u.id
LEFT JOIN user_comments_made cm       ON cm.user_id = u.id
LEFT JOIN user_votes_cast vc          ON vc.user_id = u.id
LEFT JOIN user_posts_received_comments cr ON cr.user_id = u.id
LEFT JOIN user_posts_received_votes vr   ON vr.user_id = u.id
LEFT JOIN user_posts_tags t               ON t.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
