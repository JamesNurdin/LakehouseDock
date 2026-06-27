WITH user_badges AS (
  SELECT u.id AS user_id,
         COUNT(b.id) AS badge_count
  FROM users u
  LEFT JOIN badges b ON b.userid = u.id
  GROUP BY u.id
),
user_posts AS (
  SELECT u.id AS user_id,
         COUNT(p.id) AS post_count,
         SUM(p.score) AS total_score,
         AVG(p.score) AS avg_score,
         SUM(p.viewcount) AS total_views,
         SUM(p.favoritecount) AS total_favorite,
         SUM(p.answercount) AS total_answers
  FROM users u
  LEFT JOIN posts p ON p.owneruserid = u.id
  GROUP BY u.id
),
user_votes_cast AS (
  SELECT u.id AS user_id,
         COUNT(v.id) AS votes_cast,
         SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_cast,
         SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_cast
  FROM users u
  LEFT JOIN votes v ON v.userid = u.id
  GROUP BY u.id
),
user_votes_received AS (
  SELECT u.id AS user_id,
         COUNT(v.id) AS votes_received,
         SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
         SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
  FROM users u
  LEFT JOIN posts p ON p.owneruserid = u.id
  LEFT JOIN votes v ON v.postid = p.id
  GROUP BY u.id
),
user_posthistory AS (
  SELECT u.id AS user_id,
         COUNT(ph.id) AS posthistory_count
  FROM users u
  LEFT JOIN posthistory ph ON ph.userid = u.id
  LEFT JOIN posts p ON ph.posthistorytypeid = p.id
  GROUP BY u.id
),
user_edits AS (
  SELECT u.id AS user_id,
         COUNT(p.id) AS post_edit_count
  FROM users u
  LEFT JOIN posts p ON p.lasteditoruserid = u.id
  GROUP BY u.id
)
SELECT u.id,
       u.reputation,
       u.creationdate,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_score, 0) AS total_post_score,
       COALESCE(up.avg_score, 0) AS avg_post_score,
       COALESCE(up.total_views, 0) AS total_post_views,
       COALESCE(up.total_favorite, 0) AS total_favorite_count,
       COALESCE(up.total_answers, 0) AS total_answer_count,
       COALESCE(ue.post_edit_count, 0) AS post_edit_count,
       COALESCE(uvc.votes_cast, 0) AS votes_cast,
       COALESCE(uvc.upvotes_cast, 0) AS upvotes_cast,
       COALESCE(uvc.downvotes_cast, 0) AS downvotes_cast,
       COALESCE(uvr.votes_received, 0) AS votes_received,
       COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
       COALESCE(uvr.downvotes_received, 0) AS downvotes_received,
       COALESCE(uph.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
