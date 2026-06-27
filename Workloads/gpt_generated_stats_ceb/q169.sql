WITH user_posts AS (
    SELECT owneruserid,
           COUNT(*) AS post_count,
           AVG(score) AS avg_post_score,
           SUM(viewcount) AS total_views
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT userid,
           COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT userid,
           COUNT(*) AS vote_count,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
           SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT userid,
           COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
user_tags AS (
    SELECT p.owneruserid,
           COUNT(DISTINCT t.id) AS tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.avg_post_score, 0) AS avg_post_score,
       COALESCE(up.total_views, 0) AS total_views,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uv.vote_count, 0) AS vote_count,
       COALESCE(uv.upvote_count, 0) AS upvote_count,
       COALESCE(uv.downvote_count, 0) AS downvote_count,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(uph.posthistory_count, 0) AS posthistory_count,
       COALESCE(ut.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN user_posts up ON up.owneruserid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes uv ON uv.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
LEFT JOIN user_tags ut ON ut.owneruserid = u.id
ORDER BY u.reputation DESC
LIMIT 100
