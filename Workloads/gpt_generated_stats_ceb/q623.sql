WITH user_posts AS (
    SELECT owneruserid AS user_id,
           COUNT(*) AS post_count,
           SUM(score) AS total_post_score
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
user_badges AS (
    SELECT userid AS user_id,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_votes_cast AS (
    SELECT userid AS user_id,
           COUNT(*) AS votes_cast
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_posthistory AS (
    SELECT userid AS user_id,
           COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
user_postlinks AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS postlink_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.total_comment_score, 0) AS total_comment_score,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(uvc.votes_cast, 0) AS votes_cast,
       COALESCE(uvr.votes_received, 0) AS votes_received,
       COALESCE(uph.posthistory_count, 0) AS posthistory_count,
       COALESCE(ul.postlink_count, 0) AS postlink_count,
       COALESCE(ut.tag_count, 0) AS tag_count,
       ROW_NUMBER() OVER (ORDER BY COALESCE(up.total_post_score, 0) DESC) AS rank_by_post_score
FROM users u
LEFT JOIN user_posts up ON u.id = up.user_id
LEFT JOIN user_comments uc ON u.id = uc.user_id
LEFT JOIN user_badges ub ON u.id = ub.user_id
LEFT JOIN user_votes_cast uvc ON u.id = uvc.user_id
LEFT JOIN user_votes_received uvr ON u.id = uvr.user_id
LEFT JOIN user_posthistory uph ON u.id = uph.user_id
LEFT JOIN user_postlinks ul ON u.id = ul.user_id
LEFT JOIN user_tags ut ON u.id = ut.user_id
ORDER BY rank_by_post_score
LIMIT 10
