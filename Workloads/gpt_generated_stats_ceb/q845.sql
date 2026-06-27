WITH user_posts AS (
  SELECT u.id AS user_id,
         u.reputation,
         COUNT(p.id) AS post_count,
         COALESCE(SUM(p.score), 0) AS total_post_score,
         COALESCE(SUM(p.viewcount), 0) AS total_viewcount,
         COALESCE(SUM(p.favoritecount), 0) AS total_favoritecount
  FROM users u
  LEFT JOIN posts p ON p.owneruserid = u.id
  GROUP BY u.id, u.reputation
),
user_comments AS (
  SELECT u.id AS user_id,
         COUNT(c.id) AS comment_count,
         COALESCE(SUM(c.score), 0) AS comment_score_sum
  FROM users u
  LEFT JOIN comments c ON c.userid = u.id
  GROUP BY u.id
),
user_votes_cast AS (
  SELECT u.id AS user_id,
         COUNT(v.id) AS votes_cast_count,
         COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvotes_cast,
         COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvotes_cast
  FROM users u
  LEFT JOIN votes v ON v.userid = u.id
  GROUP BY u.id
),
user_votes_received AS (
  SELECT u.id AS user_id,
         COUNT(v.id) AS votes_received_count,
         COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvotes_received,
         COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvotes_received
  FROM users u
  LEFT JOIN posts p ON p.owneruserid = u.id
  LEFT JOIN votes v ON v.postid = p.id
  GROUP BY u.id
),
user_badges AS (
  SELECT u.id AS user_id,
         COUNT(b.id) AS badge_count
  FROM users u
  LEFT JOIN badges b ON b.userid = u.id
  GROUP BY u.id
),
user_tags AS (
  SELECT u.id AS user_id,
         COUNT(t.id) AS tag_count
  FROM users u
  LEFT JOIN posts p ON p.owneruserid = u.id
  LEFT JOIN tags t ON t.excerptpostid = p.id
  GROUP BY u.id
),
user_posthistory AS (
  SELECT u.id AS user_id,
         COUNT(ph.id) AS posthistory_count
  FROM users u
  LEFT JOIN posthistory ph ON ph.userid = u.id
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
SELECT up.user_id,
       up.reputation,
       up.post_count,
       up.total_post_score,
       up.total_viewcount,
       up.total_favoritecount,
       uc.comment_count,
       uc.comment_score_sum,
       uv_cast.votes_cast_count,
       uv_cast.upvotes_cast,
       uv_cast.downvotes_cast,
       uv_recv.votes_received_count,
       uv_recv.upvotes_received,
       uv_recv.downvotes_received,
       ub.badge_count,
       ut.tag_count,
       uph.posthistory_count,
       upl.postlink_count
FROM user_posts up
LEFT JOIN user_comments uc ON uc.user_id = up.user_id
LEFT JOIN user_votes_cast uv_cast ON uv_cast.user_id = up.user_id
LEFT JOIN user_votes_received uv_recv ON uv_recv.user_id = up.user_id
LEFT JOIN user_badges ub ON ub.user_id = up.user_id
LEFT JOIN user_tags ut ON ut.user_id = up.user_id
LEFT JOIN user_posthistory uph ON uph.user_id = up.user_id
LEFT JOIN user_postlinks upl ON upl.user_id = up.user_id
ORDER BY up.reputation DESC
LIMIT 100
