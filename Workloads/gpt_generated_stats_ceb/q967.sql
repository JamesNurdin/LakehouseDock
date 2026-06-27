WITH
  user_posts AS (
    SELECT
      owneruserid,
      COUNT(*) AS post_count,
      SUM(score) AS total_score,
      SUM(viewcount) AS total_views
    FROM posts
    GROUP BY owneruserid
  ),
  user_comments AS (
    SELECT
      userid,
      COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
  ),
  user_votes AS (
    SELECT
      userid,
      COUNT(*) AS vote_count,
      COALESCE(SUM(bountyamount), 0) AS total_bounty
    FROM votes
    GROUP BY userid
  ),
  user_badges AS (
    SELECT
      userid,
      COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
  ),
  user_edits AS (
    SELECT
      lasteditoruserid,
      COUNT(*) AS edit_count
    FROM posts
    GROUP BY lasteditoruserid
  ),
  user_posthistory AS (
    SELECT
      userid,
      COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
  )
SELECT
  u.id,
  u.reputation,
  u.creationdate,
  u.views,
  u.upvotes,
  u.downvotes,
  COALESCE(p.post_count, 0) AS post_count,
  COALESCE(p.total_score, 0) AS total_post_score,
  COALESCE(p.total_views, 0) AS total_post_views,
  COALESCE(c.comment_count, 0) AS comment_count,
  COALESCE(v.vote_count, 0) AS vote_count,
  COALESCE(v.total_bounty, 0) AS total_bounty,
  COALESCE(b.badge_count, 0) AS badge_count,
  COALESCE(e.edit_count, 0) AS edit_count,
  COALESCE(ph.posthistory_count, 0) AS posthistory_count,
  CASE
    WHEN COALESCE(p.post_count, 0) = 0 THEN NULL
    ELSE COALESCE(p.total_score, 0) / COALESCE(p.post_count, 1)
  END AS avg_post_score
FROM users u
LEFT JOIN user_posts p ON p.owneruserid = u.id
LEFT JOIN user_comments c ON c.userid = u.id
LEFT JOIN user_votes v ON v.userid = u.id
LEFT JOIN user_badges b ON b.userid = u.id
LEFT JOIN user_edits e ON e.lasteditoruserid = u.id
LEFT JOIN user_posthistory ph ON ph.userid = u.id
WHERE u.reputation > 1000
ORDER BY total_post_score DESC
LIMIT 100
