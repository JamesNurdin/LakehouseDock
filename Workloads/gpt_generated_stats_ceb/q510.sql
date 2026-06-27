WITH user_posts AS (
       SELECT
         u.id AS user_id,
         COUNT(p.id) AS post_count,
         SUM(p.score) AS post_score_sum,
         AVG(p.score) AS post_score_avg,
         SUM(p.viewcount) AS post_viewcount_sum
       FROM users u
       LEFT JOIN posts p ON p.owneruserid = u.id
       GROUP BY u.id
     ),
     user_edits AS (
       SELECT
         u.id AS user_id,
         COUNT(p.id) AS edited_post_count
       FROM users u
       LEFT JOIN posts p ON p.lasteditoruserid = u.id
       GROUP BY u.id
     ),
     user_comments AS (
       SELECT
         u.id AS user_id,
         COUNT(c.id) AS comment_count,
         SUM(c.score) AS comment_score_sum,
         AVG(c.score) AS comment_score_avg
       FROM users u
       LEFT JOIN comments c ON c.userid = u.id
       GROUP BY u.id
     ),
     user_votes_cast AS (
       SELECT
         u.id AS user_id,
         COUNT(v.id) AS votes_cast_count,
         SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast_count,
         SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast_count
       FROM users u
       LEFT JOIN votes v ON v.userid = u.id
       GROUP BY u.id
     ),
     user_votes_received AS (
       SELECT
         u.id AS user_id,
         COUNT(v.id) AS votes_received_count,
         SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_received_count,
         SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_received_count
       FROM users u
       LEFT JOIN posts p ON p.owneruserid = u.id
       LEFT JOIN votes v ON v.postid = p.id
       GROUP BY u.id
     ),
     user_badges AS (
       SELECT
         u.id AS user_id,
         COUNT(b.id) AS badge_count
       FROM users u
       LEFT JOIN badges b ON b.userid = u.id
       GROUP BY u.id
     )
SELECT
  u.id,
  u.reputation,
  COALESCE(up.post_count, 0)               AS post_count,
  COALESCE(up.post_score_sum, 0)           AS post_score_sum,
  COALESCE(up.post_score_avg, 0)           AS post_score_avg,
  COALESCE(up.post_viewcount_sum, 0)      AS post_viewcount_sum,
  COALESCE(ue.edited_post_count, 0)       AS edited_post_count,
  COALESCE(uc.comment_count, 0)           AS comment_count,
  COALESCE(uc.comment_score_sum, 0)       AS comment_score_sum,
  COALESCE(uc.comment_score_avg, 0)       AS comment_score_avg,
  COALESCE(uvc.votes_cast_count, 0)       AS votes_cast_count,
  COALESCE(uvc.upvote_cast_count, 0)      AS upvote_cast_count,
  COALESCE(uvc.downvote_cast_count, 0)    AS downvote_cast_count,
  COALESCE(uvr.votes_received_count, 0)   AS votes_received_count,
  COALESCE(uvr.upvote_received_count, 0)  AS upvote_received_count,
  COALESCE(uvr.downvote_received_count, 0) AS downvote_received_count,
  COALESCE(ub.badge_count, 0)             AS badge_count
FROM users u
LEFT JOIN user_posts up          ON up.user_id = u.id
LEFT JOIN user_edits ue          ON ue.user_id = u.id
LEFT JOIN user_comments uc       ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc    ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub         ON ub.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
