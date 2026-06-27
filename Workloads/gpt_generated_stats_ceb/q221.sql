WITH user_posts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS post_count,
           SUM(p.score) AS total_post_score,
           AVG(p.score) AS avg_post_score,
           COUNT(CASE WHEN p.posttypeid = 2 THEN 1 END) AS answer_count,
           COUNT(CASE WHEN p.posttypeid = 1 THEN 1 END) AS question_count
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
user_comments_received AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_received_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN comments c ON c.postid = p.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_cast_count,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
           SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_received_count,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
           SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_badges AS (
    SELECT u.id AS user_id,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS posthistory_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
),
user_postlinks AS (
    SELECT u.id AS user_id,
           COUNT(pl.id) AS postlinks_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY u.id
)
SELECT u.id,
       u.reputation,
       up.post_count,
       up.total_post_score,
       up.avg_post_score,
       up.answer_count,
       up.question_count,
       cm.comment_made_count,
       cr.comment_received_count,
       vc.votes_cast_count,
       vc.upvotes_cast,
       vc.downvotes_cast,
       vr.votes_received_count,
       vr.upvotes_received,
       vr.downvotes_received,
       b.badge_count,
       ph.posthistory_count,
       pl.postlinks_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments_made cm ON cm.user_id = u.id
LEFT JOIN user_comments_received cr ON cr.user_id = u.id
LEFT JOIN user_votes_cast vc ON vc.user_id = u.id
LEFT JOIN user_votes_received vr ON vr.user_id = u.id
LEFT JOIN user_badges b ON b.user_id = u.id
LEFT JOIN user_posthistory ph ON ph.user_id = u.id
LEFT JOIN user_postlinks pl ON pl.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
