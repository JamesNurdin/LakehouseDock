WITH user_badges AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posts AS (
    SELECT owneruserid AS user_id,
           COUNT(*) AS post_count,
           SUM(score) AS total_post_score,
           SUM(viewcount) AS total_post_views
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT userid AS user_id,
           COUNT(*) AS comment_made_count,
           SUM(score) AS total_comment_score
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT userid AS user_id,
           COUNT(*) AS votes_cast_count
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS votes_received_count
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT p.owneruserid AS user_id,
           COUNT(DISTINCT t.id) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
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
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(up.total_post_views, 0) AS total_post_views,
       COALESCE(uc.comment_made_count, 0) AS comment_made_count,
       COALESCE(uc.total_comment_score, 0) AS total_comment_score,
       COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
       COALESCE(vr.votes_received_count, 0) AS votes_received_count,
       COALESCE(ut.tag_count, 0) AS tag_count,
       COALESCE(uph.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN user_badges ub ON u.id = ub.userid
LEFT JOIN user_posts up ON u.id = up.user_id
LEFT JOIN user_comments uc ON u.id = uc.user_id
LEFT JOIN user_votes_cast vc ON u.id = vc.user_id
LEFT JOIN user_votes_received vr ON u.id = vr.user_id
LEFT JOIN user_tags ut ON u.id = ut.user_id
LEFT JOIN user_posthistory uph ON u.id = uph.user_id
ORDER BY u.reputation DESC
LIMIT 100
