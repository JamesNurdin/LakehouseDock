WITH
  -- Posts created by each user
  user_posts AS (
    SELECT
      u.id AS user_id,
      u.reputation,
      COUNT(p.id) AS post_count,
      COALESCE(SUM(p.score), 0) AS total_post_score
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
  ),
  -- Comments made by each user
  user_comments AS (
    SELECT
      u.id AS user_id,
      COUNT(c.id) AS comment_count,
      COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
  ),
  -- Votes cast by each user (up‑votes and down‑votes are identified by votetypeid)
  user_votes AS (
    SELECT
      u.id AS user_id,
      COUNT(v.id) AS vote_cast_count,
      SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cast,
      SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cast
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
  ),
  -- Badges earned by each user
  user_badges AS (
    SELECT
      u.id AS user_id,
      COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
  ),
  -- Post‑history entries (edits, closures, etc.) performed by each user
  user_edits AS (
    SELECT
      u.id AS user_id,
      COUNT(ph.id) AS post_edit_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
  ),
  -- Distinct tags a user has contributed to via owned posts
  user_tags AS (
    SELECT
      u.id AS user_id,
      COUNT(DISTINCT t.id) AS tag_contrib_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
  )
SELECT
  up.user_id,
  up.reputation,
  up.post_count,
  up.total_post_score,
  uc.comment_count,
  uc.total_comment_score,
  uv.vote_cast_count,
  uv.upvote_cast,
  uv.downvote_cast,
  ub.badge_count,
  ue.post_edit_count,
  ut.tag_contrib_count,
  (
    up.post_count * 5
    + uc.comment_count * 2
    + uv.upvote_cast * 1
    - uv.downvote_cast * 1
    + ub.badge_count * 3
    + ue.post_edit_count * 1
    + ut.tag_contrib_count * 2
  ) AS activity_score
FROM user_posts up
LEFT JOIN user_comments uc ON uc.user_id = up.user_id
LEFT JOIN user_votes uv ON uv.user_id = up.user_id
LEFT JOIN user_badges ub ON ub.user_id = up.user_id
LEFT JOIN user_edits ue ON ue.user_id = up.user_id
LEFT JOIN user_tags ut ON ut.user_id = up.user_id
ORDER BY activity_score DESC
LIMIT 10
