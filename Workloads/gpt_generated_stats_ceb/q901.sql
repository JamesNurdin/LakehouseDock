/*
  Top 10 users by total post score, with additional activity metrics.
  The query aggregates posts, votes received on those posts, badges earned, and distinct tags used.
  All joins follow the allowed join rules for the Stack Exchange Cebu dataset (Trino/ Iceberg).
*/
WITH
  -- Aggregate posts per user (owneruserid)
  posts_agg AS (
    SELECT
      p.owneruserid AS userid,
      COUNT(*) AS post_count,
      SUM(p.score) AS total_post_score,
      AVG(p.score) AS avg_post_score
    FROM posts p
    GROUP BY p.owneruserid
  ),

  -- Aggregate votes received on a user's posts
  votes_agg AS (
    SELECT
      p.owneruserid AS userid,
      COUNT(*) AS vote_count,
      SUM(v.bountyamount) AS total_bounty_amount
    FROM votes v
    JOIN posts p ON v.postid = p.id               -- valid join rule: votes.postid = posts.id
    GROUP BY p.owneruserid
  ),

  -- Count badges earned per user
  badges_agg AS (
    SELECT
      b.userid AS userid,
      COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
  ),

  -- Count distinct tags used in a user's posts (via excerptpostid)
  tags_agg AS (
    SELECT
      p.owneruserid AS userid,
      COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id      -- valid join rule: tags.excerptpostid = posts.id
    GROUP BY p.owneruserid
  )
SELECT
  u.id AS user_id,
  u.reputation,
  COALESCE(p.post_count, 0)          AS post_count,
  COALESCE(p.total_post_score, 0)    AS total_post_score,
  COALESCE(p.avg_post_score, 0)      AS avg_post_score,
  COALESCE(v.vote_count, 0)          AS vote_count,
  COALESCE(v.total_bounty_amount, 0) AS total_bounty_amount,
  COALESCE(b.badge_count, 0)         AS badge_count,
  COALESCE(t.distinct_tag_count, 0)  AS distinct_tag_count
FROM users u
LEFT JOIN posts_agg p   ON p.userid = u.id   -- derived from posts.owneruserid = users.id
LEFT JOIN votes_agg v   ON v.userid = u.id   -- derived from posts.owneruserid = users.id
LEFT JOIN badges_agg b  ON b.userid = u.id   -- direct join rule: badges.userid = users.id
LEFT JOIN tags_agg t    ON t.userid = u.id   -- derived from posts.owneruserid = users.id
ORDER BY total_post_score DESC
LIMIT 10
