WITH user_posts AS (
       SELECT owneruserid AS userid,
              COUNT(*) AS post_count,
              AVG(score) AS avg_post_score,
              SUM(viewcount) AS total_views
       FROM posts
       GROUP BY owneruserid
   ),
   user_comments AS (
       SELECT userid,
              COUNT(*) AS comment_count,
              SUM(score) AS comment_score_sum
       FROM comments
       GROUP BY userid
   ),
   user_votes AS (
       SELECT userid,
              COUNT(*) AS vote_count,
              SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast,
              SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast
       FROM votes
       GROUP BY userid
   ),
   user_badges AS (
       SELECT userid,
              COUNT(*) AS badge_count
       FROM badges
       GROUP BY userid
   ),
   user_tag_excerpts AS (
       SELECT p.owneruserid AS userid,
              COUNT(DISTINCT t.id) AS tag_excerpt_count
       FROM posts p
       JOIN tags t ON t.excerptpostid = p.id
       GROUP BY p.owneruserid
   ),
   user_edits AS (
       SELECT userid,
              COUNT(*) AS edit_count
       FROM posthistory
       GROUP BY userid
   )
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.post_count, 0)          AS post_count,
       COALESCE(up.avg_post_score, 0)      AS avg_post_score,
       COALESCE(up.total_views, 0)         AS total_views,
       COALESCE(uc.comment_count, 0)       AS comment_count,
       COALESCE(uc.comment_score_sum, 0)   AS comment_score_sum,
       COALESCE(uv.vote_count, 0)          AS vote_count,
       COALESCE(uv.upvote_cast, 0)         AS upvote_cast,
       COALESCE(uv.downvote_cast, 0)       AS downvote_cast,
       COALESCE(ub.badge_count, 0)         AS badge_count,
       COALESCE(ut.tag_excerpt_count, 0)   AS tag_excerpt_count,
       COALESCE(ue.edit_count, 0)          AS edit_count
FROM users u
LEFT JOIN user_posts up          ON up.userid = u.id
LEFT JOIN user_comments uc       ON uc.userid = u.id
LEFT JOIN user_votes uv          ON uv.userid = u.id
LEFT JOIN user_badges ub         ON ub.userid = u.id
LEFT JOIN user_tag_excerpts ut   ON ut.userid = u.id
LEFT JOIN user_edits ue          ON ue.userid = u.id
ORDER BY u.reputation DESC, post_count DESC
LIMIT 20
