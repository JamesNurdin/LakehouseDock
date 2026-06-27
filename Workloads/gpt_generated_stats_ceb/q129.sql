WITH posts_agg AS (
  SELECT
    owneruserid,
    COUNT(*) AS post_count,
    COALESCE(SUM(score), 0) AS total_post_score
  FROM posts
  GROUP BY owneruserid
),
comments_agg AS (
  SELECT
    userid,
    COUNT(*) AS comment_count,
    COALESCE(SUM(score), 0) AS total_comment_score
  FROM comments
  GROUP BY userid
),
votes_given_agg AS (
  SELECT
    userid,
    COUNT(*) AS vote_given_count
  FROM votes
  GROUP BY userid
),
votes_received_agg AS (
  SELECT
    p.owneruserid,
    COUNT(v.id) AS vote_received_count
  FROM votes v
  JOIN posts p ON v.postid = p.id
  GROUP BY p.owneruserid
),
badges_agg AS (
  SELECT
    userid,
    COUNT(*) AS badge_count
  FROM badges
  GROUP BY userid
),
tags_agg AS (
  SELECT
    p.owneruserid,
    COUNT(*) AS tag_count
  FROM tags t
  JOIN posts p ON t.excerptpostid = p.id
  GROUP BY p.owneruserid
),
postlinks_agg AS (
  SELECT
    p.owneruserid,
    COUNT(*) AS postlink_count
  FROM postlinks pl
  JOIN posts p ON pl.postid = p.id
  GROUP BY p.owneruserid
)
SELECT
  u.id AS user_id,
  u.reputation,
  COALESCE(p.post_count, 0) AS post_count,
  COALESCE(c.comment_count, 0) AS comment_count,
  COALESCE(vg.vote_given_count, 0) AS vote_given_count,
  COALESCE(vr.vote_received_count, 0) AS vote_received_count,
  COALESCE(b.badge_count, 0) AS badge_count,
  COALESCE(t.tag_count, 0) AS tag_count,
  COALESCE(pl.postlink_count, 0) AS postlink_count,
  COALESCE(p.total_post_score, 0) AS total_post_score,
  COALESCE(c.total_comment_score, 0) AS total_comment_score,
  CASE WHEN COALESCE(p.post_count, 0) > 0 THEN p.total_post_score / p.post_count ELSE NULL END AS avg_post_score
FROM users u
LEFT JOIN posts_agg p      ON p.owneruserid   = u.id
LEFT JOIN comments_agg c   ON c.userid        = u.id
LEFT JOIN votes_given_agg vg ON vg.userid      = u.id
LEFT JOIN votes_received_agg vr ON vr.owneruserid = u.id
LEFT JOIN badges_agg b     ON b.userid        = u.id
LEFT JOIN tags_agg t       ON t.owneruserid   = u.id
LEFT JOIN postlinks_agg pl ON pl.owneruserid  = u.id
ORDER BY u.reputation DESC
LIMIT 100
