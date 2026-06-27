WITH badges_per_user AS (
  SELECT userid,
         COUNT(*) AS badge_count
  FROM badges
  GROUP BY userid
),
posts_per_user AS (
  SELECT owneruserid AS user_id,
         COUNT(*) AS post_count,
         SUM(score) AS total_post_score,
         AVG(score) AS avg_post_score,
         SUM(viewcount) AS total_viewcount,
         SUM(answercount) AS total_answercount,
         SUM(commentcount) AS total_commentcount,
         SUM(favoritecount) AS total_favoritecount
  FROM posts
  GROUP BY owneruserid
),
comments_made_per_user AS (
  SELECT userid,
         COUNT(*) AS comment_made_count
  FROM comments
  GROUP BY userid
),
comments_received_per_user AS (
  SELECT p.owneruserid AS user_id,
         COUNT(*) AS comment_received_count
  FROM comments c
  JOIN posts p ON c.postid = p.id
  GROUP BY p.owneruserid
),
votes_cast_per_user AS (
  SELECT userid,
         COUNT(*) AS votes_cast_count,
         SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast_count,
         SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast_count
  FROM votes
  GROUP BY userid
),
votes_received_per_user AS (
  SELECT p.owneruserid AS user_id,
         COUNT(*) AS votes_received_count,
         SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_received_count,
         SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_received_count
  FROM votes v
  JOIN posts p ON v.postid = p.id
  GROUP BY p.owneruserid
),
post_edits_per_user AS (
  SELECT userid,
         COUNT(*) AS edit_count
  FROM posthistory
  GROUP BY userid
),
type_edits_per_user AS (
  SELECT p.owneruserid AS user_id,
         COUNT(*) AS type_edit_count
  FROM posthistory ph
  JOIN posts p ON ph.posthistorytypeid = p.id
  GROUP BY p.owneruserid
),
tags_per_user AS (
  SELECT p.owneruserid AS user_id,
         COUNT(DISTINCT t.id) AS tag_count
  FROM tags t
  JOIN posts p ON t.excerptpostid = p.id
  GROUP BY p.owneruserid
)
SELECT
  u.id AS user_id,
  u.reputation,
  u.creationdate,
  u.views,
  u.upvotes,
  u.downvotes,
  COALESCE(b.badge_count, 0) AS badge_count,
  COALESCE(pu.post_count, 0) AS post_count,
  COALESCE(pu.total_post_score, 0) AS total_post_score,
  COALESCE(pu.avg_post_score, 0) AS avg_post_score,
  COALESCE(pu.total_viewcount, 0) AS total_viewcount,
  COALESCE(pu.total_answercount, 0) AS total_answercount,
  COALESCE(pu.total_commentcount, 0) AS total_commentcount,
  COALESCE(pu.total_favoritecount, 0) AS total_favoritecount,
  COALESCE(cm.comment_made_count, 0) AS comment_made_count,
  COALESCE(cr.comment_received_count, 0) AS comment_received_count,
  COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
  COALESCE(vc.upvote_cast_count, 0) AS upvote_cast_count,
  COALESCE(vc.downvote_cast_count, 0) AS downvote_cast_count,
  COALESCE(vr.votes_received_count, 0) AS votes_received_count,
  COALESCE(vr.upvote_received_count, 0) AS upvote_received_count,
  COALESCE(vr.downvote_received_count, 0) AS downvote_received_count,
  COALESCE(pe.edit_count, 0) AS edit_count,
  COALESCE(te.type_edit_count, 0) AS type_edit_count,
  COALESCE(tu.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN badges_per_user b ON b.userid = u.id
LEFT JOIN posts_per_user pu ON pu.user_id = u.id
LEFT JOIN comments_made_per_user cm ON cm.userid = u.id
LEFT JOIN comments_received_per_user cr ON cr.user_id = u.id
LEFT JOIN votes_cast_per_user vc ON vc.userid = u.id
LEFT JOIN votes_received_per_user vr ON vr.user_id = u.id
LEFT JOIN post_edits_per_user pe ON pe.userid = u.id
LEFT JOIN type_edits_per_user te ON te.user_id = u.id
LEFT JOIN tags_per_user tu ON tu.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
