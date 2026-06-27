WITH tag_posts AS (
  SELECT
    t.id AS tag_id,
    p.id AS post_id,
    p.score AS post_score,
    p.viewcount AS post_viewcount,
    p.owneruserid AS owner_user_id
  FROM tags t
  JOIN posts p ON t.excerptpostid = p.id
),
post_comments AS (
  SELECT
    c.postid AS post_id,
    COUNT(*) AS comment_count
  FROM comments c
  GROUP BY c.postid
),
post_votes AS (
  SELECT
    v.postid AS post_id,
    COUNT(*) AS vote_count,
    COALESCE(SUM(v.bountyamount), 0) AS total_bounty
  FROM votes v
  GROUP BY v.postid
),
user_rep AS (
  SELECT
    u.id AS user_id,
    u.reputation
  FROM users u
)
SELECT
  tp.tag_id,
  COUNT(DISTINCT tp.post_id) AS post_count,
  SUM(tp.post_score) AS total_post_score,
  AVG(tp.post_score) AS avg_post_score,
  SUM(tp.post_viewcount) AS total_viewcount,
  AVG(tp.post_viewcount) AS avg_viewcount,
  COALESCE(SUM(pc.comment_count), 0) AS total_comment_count,
  COALESCE(SUM(pv.vote_count), 0) AS total_vote_count,
  COALESCE(SUM(pv.total_bounty), 0) AS total_bounty_amount,
  AVG(ur.reputation) AS avg_owner_reputation
FROM tag_posts tp
LEFT JOIN post_comments pc ON pc.post_id = tp.post_id
LEFT JOIN post_votes pv ON pv.post_id = tp.post_id
LEFT JOIN user_rep ur ON ur.user_id = tp.owner_user_id
GROUP BY tp.tag_id
ORDER BY total_vote_count DESC
LIMIT 10
