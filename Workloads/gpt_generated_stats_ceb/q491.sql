WITH user_badges AS (
    SELECT u.id AS user_id,
           u.reputation,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id, u.reputation
),
user_posts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS post_count,
           SUM(CASE WHEN p.posttypeid = 2 THEN 1 ELSE 0 END) AS answer_count,
           AVG(p.score) AS avg_post_score,
           SUM(p.viewcount) AS total_views
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_count
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_cast
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_tags AS (
    SELECT u.id AS user_id,
           COUNT(DISTINCT t.id) AS tag_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_postlinks AS (
    SELECT u.id AS user_id,
           COUNT(pl.id) AS postlink_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY u.id
)
SELECT ub.user_id,
       ub.reputation,
       ub.badge_count,
       up.post_count,
       up.answer_count,
       up.avg_post_score,
       up.total_views,
       uc.comment_count,
       uv_cast.votes_cast,
       uv_received.votes_received,
       ut.tag_count,
       upl.postlink_count,
       ROW_NUMBER() OVER (ORDER BY ub.reputation DESC) AS reputation_rank
FROM user_badges ub
LEFT JOIN user_posts up ON up.user_id = ub.user_id
LEFT JOIN user_comments uc ON uc.user_id = ub.user_id
LEFT JOIN user_votes_cast uv_cast ON uv_cast.user_id = ub.user_id
LEFT JOIN user_votes_received uv_received ON uv_received.user_id = ub.user_id
LEFT JOIN user_tags ut ON ut.user_id = ub.user_id
LEFT JOIN user_postlinks upl ON upl.user_id = ub.user_id
ORDER BY ub.reputation DESC
LIMIT 20
