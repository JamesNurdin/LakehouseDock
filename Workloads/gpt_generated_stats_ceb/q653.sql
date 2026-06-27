WITH user_posts AS (
    SELECT owneruserid AS user_id,
           COUNT(*) AS post_count,
           SUM(score) AS total_post_score,
           AVG(score) AS avg_post_score,
           SUM(viewcount) AS total_post_viewcount
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT userid AS user_id,
           COUNT(*) AS comment_count,
           SUM(score) AS total_comment_score
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT userid AS user_id,
           COUNT(*) AS vote_cast_count
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS vote_received_count
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT userid AS user_id,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT userid AS user_id,
           COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
)
SELECT u.id AS user_id,
       u.reputation,
       u.creationdate,
       u.views,
       u.upvotes,
       u.downvotes,
       COALESCE(p.post_count, 0) AS post_count,
       COALESCE(p.total_post_score, 0) AS total_post_score,
       COALESCE(p.avg_post_score, 0) AS avg_post_score,
       COALESCE(p.total_post_viewcount, 0) AS total_post_viewcount,
       COALESCE(c.comment_count, 0) AS comment_count,
       COALESCE(c.total_comment_score, 0) AS total_comment_score,
       COALESCE(vc.vote_cast_count, 0) AS vote_cast_count,
       COALESCE(vr.vote_received_count, 0) AS vote_received_count,
       COALESCE(b.badge_count, 0) AS badge_count,
       COALESCE(ph.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN user_posts p ON u.id = p.user_id
LEFT JOIN user_comments c ON u.id = c.user_id
LEFT JOIN user_votes_cast vc ON u.id = vc.user_id
LEFT JOIN user_votes_received vr ON u.id = vr.user_id
LEFT JOIN user_badges b ON u.id = b.user_id
LEFT JOIN user_posthistory ph ON u.id = ph.user_id
ORDER BY u.reputation DESC
LIMIT 100
