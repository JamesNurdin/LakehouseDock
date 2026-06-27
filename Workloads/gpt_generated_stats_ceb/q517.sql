WITH user_posts AS (
  SELECT
    u.id AS user_id,
    p.id AS post_id,
    p.score AS post_score
  FROM users u
  LEFT JOIN posts p ON p.owneruserid = u.id
),
user_comments AS (
  SELECT
    u.id AS user_id,
    c.id AS comment_id,
    c.score AS comment_score
  FROM users u
  LEFT JOIN comments c ON c.userid = u.id
),
user_votes AS (
  SELECT
    u.id AS user_id,
    v.id AS vote_id,
    v.votetypeid
  FROM users u
  LEFT JOIN votes v ON v.userid = u.id
),
user_badges AS (
  SELECT
    u.id AS user_id,
    b.id AS badge_id
  FROM users u
  LEFT JOIN badges b ON b.userid = u.id
),
user_posthistory AS (
  SELECT
    u.id AS user_id,
    ph.id AS ph_id
  FROM users u
  LEFT JOIN posthistory ph ON ph.userid = u.id
),
user_tags AS (
  SELECT
    u.id AS user_id,
    t.id AS tag_id
  FROM users u
  JOIN posts p ON p.owneruserid = u.id
  JOIN tags t ON t.excerptpostid = p.id
),
user_postlinks AS (
  SELECT
    u.id AS user_id,
    pl.id AS postlink_id
  FROM users u
  JOIN posts p ON p.owneruserid = u.id
  JOIN postlinks pl ON pl.postid = p.id
)
SELECT
  u.id AS user_id,
  u.reputation,
  COUNT(DISTINCT up.post_id) AS post_count,
  COALESCE(SUM(up.post_score), 0) AS total_post_score,
  COUNT(DISTINCT uc.comment_id) AS comment_count,
  COALESCE(SUM(uc.comment_score), 0) AS total_comment_score,
  COUNT(DISTINCT uv.vote_id) AS vote_cast_count,
  COUNT(DISTINCT ub.badge_id) AS badge_count,
  COUNT(DISTINCT uph.ph_id) AS posthistory_count,
  COUNT(DISTINCT ut.tag_id) AS tag_excerpt_count,
  COUNT(DISTINCT upl.postlink_id) AS postlink_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes uv ON uv.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
LEFT JOIN user_postlinks upl ON upl.user_id = u.id
GROUP BY u.id, u.reputation
ORDER BY total_post_score DESC
LIMIT 100
