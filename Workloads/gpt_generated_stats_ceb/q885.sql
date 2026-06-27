WITH user_badges AS (
    SELECT u.id,
           u.reputation,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id, u.reputation
),
user_posts AS (
    SELECT u.id,
           COUNT(p.id) AS post_count,
           SUM(CASE WHEN p.posttypeid = 1 THEN 1 ELSE 0 END) AS question_count,
           SUM(CASE WHEN p.posttypeid = 2 THEN 1 ELSE 0 END) AS answer_count,
           SUM(p.viewcount) AS total_views
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT u.id,
           COUNT(c.id) AS comment_count
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT u.id,
           COUNT(v.id) AS votes_cast,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
           SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT p.owneruserid,
           COUNT(v.id) AS votes_received,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
           SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM posts p
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY p.owneruserid
)
SELECT ub.id,
       ub.reputation,
       ub.badge_count,
       up.post_count,
       up.question_count,
       up.answer_count,
       up.total_views,
       uc.comment_count,
       uvc.votes_cast,
       uvc.upvotes_cast,
       uvc.downvotes_cast,
       uvr.votes_received,
       uvr.upvotes_received,
       uvr.downvotes_received,
       (COALESCE(ub.badge_count, 0) * 10
        + COALESCE(up.post_count, 0) * 2
        + COALESCE(uc.comment_count, 0) * 1
        + COALESCE(uvr.upvotes_received, 0) * 0.5
        - COALESCE(uvr.downvotes_received, 0) * 0.5) AS activity_score
FROM user_badges ub
LEFT JOIN user_posts up
    ON up.id = ub.id
LEFT JOIN user_comments uc
    ON uc.id = ub.id
LEFT JOIN user_votes_cast uvc
    ON uvc.id = ub.id
LEFT JOIN user_votes_received uvr
    ON uvr.owneruserid = ub.id
ORDER BY activity_score DESC
LIMIT 20
