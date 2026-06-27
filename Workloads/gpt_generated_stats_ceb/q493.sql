WITH
  user_posts AS (
    SELECT
      owneruserid,
      COUNT(*) AS post_count,
      COALESCE(SUM(score), 0) AS post_score_sum,
      COALESCE(SUM(viewcount), 0) AS post_viewcount_sum
    FROM posts
    GROUP BY owneruserid
  ),
  user_comments AS (
    SELECT
      userid,
      COUNT(*) AS comment_count,
      COALESCE(SUM(score), 0) AS comment_score_sum
    FROM comments
    GROUP BY userid
  ),
  user_votes_cast AS (
    SELECT
      userid,
      COUNT(*) AS vote_cast_count
    FROM votes
    GROUP BY userid
  ),
  user_votes_received AS (
    SELECT
      p.owneruserid AS owneruserid,
      COUNT(v.id) AS vote_received_count,
      COALESCE(SUM(v.votetypeid), 0) AS vote_received_type_sum
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
  ),
  user_badges AS (
    SELECT
      userid,
      COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
  ),
  user_tags AS (
    SELECT
      p.owneruserid AS owneruserid,
      COUNT(DISTINCT t.id) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
  )
SELECT
  u.id,
  u.reputation,
  COALESCE(up.post_count, 0) AS post_count,
  COALESCE(up.post_score_sum, 0) AS post_score_sum,
  COALESCE(up.post_viewcount_sum, 0) AS post_viewcount_sum,
  COALESCE(uc.comment_count, 0) AS comment_count,
  COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
  COALESCE(uvc.vote_cast_count, 0) AS vote_cast_count,
  COALESCE(uvr.vote_received_count, 0) AS vote_received_count,
  COALESCE(uvr.vote_received_type_sum, 0) AS vote_received_type_sum,
  COALESCE(ub.badge_count, 0) AS badge_count,
  COALESCE(ut.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN user_posts up ON up.owneruserid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.owneruserid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_tags ut ON ut.owneruserid = u.id
WHERE u.reputation > 0
ORDER BY post_count DESC, u.id
LIMIT 100
