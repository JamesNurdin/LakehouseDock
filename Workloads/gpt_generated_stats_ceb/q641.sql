WITH user_posts AS (
  SELECT p.owneruserid AS userid,
         COUNT(*) AS post_count,
         SUM(p.score) AS total_post_score,
         AVG(p.score) AS avg_post_score,
         SUM(p.viewcount) AS total_view_count,
         SUM(p.answercount) AS total_answer_count,
         SUM(p.commentcount) AS total_comment_count,
         SUM(p.favoritecount) AS total_favorite_count
  FROM posts p
  GROUP BY p.owneruserid
),
user_comments AS (
  SELECT c.userid AS userid,
         COUNT(*) AS comment_count,
         SUM(c.score) AS total_comment_score
  FROM comments c
  GROUP BY c.userid
),
user_votes_cast AS (
  SELECT v.userid AS userid,
         COUNT(*) AS votes_cast,
         COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvotes_cast,
         COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvotes_cast
  FROM votes v
  GROUP BY v.userid
),
user_votes_received AS (
  SELECT p.owneruserid AS userid,
         COUNT(*) AS votes_received,
         COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvotes_received,
         COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvotes_received
  FROM votes v
  JOIN posts p ON v.postid = p.id
  GROUP BY p.owneruserid
),
user_badges AS (
  SELECT b.userid AS userid,
         COUNT(*) AS badge_count
  FROM badges b
  GROUP BY b.userid
),
user_posthistory AS (
  SELECT ph.userid AS userid,
         COUNT(*) AS history_event_count
  FROM posthistory ph
  GROUP BY ph.userid
),
user_outbound_links AS (
  SELECT p.owneruserid AS userid,
         COUNT(*) AS outbound_link_count
  FROM postlinks pl
  JOIN posts p ON pl.postid = p.id
  GROUP BY p.owneruserid
),
user_inbound_links AS (
  SELECT p.owneruserid AS userid,
         COUNT(*) AS inbound_link_count
  FROM postlinks pl
  JOIN posts p ON pl.relatedpostid = p.id
  GROUP BY p.owneruserid
)
SELECT
  u.id AS user_id,
  u.reputation,
  u.creationdate,
  u.views,
  u.upvotes,
  u.downvotes,
  up.post_count,
  up.total_post_score,
  up.avg_post_score,
  up.total_view_count,
  up.total_answer_count,
  up.total_comment_count,
  up.total_favorite_count,
  uc.comment_count,
  uc.total_comment_score,
  vc.votes_cast,
  vc.upvotes_cast,
  vc.downvotes_cast,
  vr.votes_received,
  vr.upvotes_received,
  vr.downvotes_received,
  b.badge_count,
  ph.history_event_count,
  ol.outbound_link_count,
  il.inbound_link_count
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast vc ON vc.userid = u.id
LEFT JOIN user_votes_received vr ON vr.userid = u.id
LEFT JOIN user_badges b ON b.userid = u.id
LEFT JOIN user_posthistory ph ON ph.userid = u.id
LEFT JOIN user_outbound_links ol ON ol.userid = u.id
LEFT JOIN user_inbound_links il ON il.userid = u.id
ORDER BY COALESCE(up.total_post_score, 0) DESC
LIMIT 100
