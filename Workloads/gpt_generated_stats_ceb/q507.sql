WITH
  user_posts AS (
    SELECT
      owneruserid AS userid,
      COUNT(*) AS total_posts,
      AVG(score) AS avg_post_score,
      SUM(viewcount) AS total_views,
      SUM(answercount) AS total_answers,
      SUM(commentcount) AS total_comments_on_posts
    FROM posts
    GROUP BY owneruserid
  ),
  user_comments AS (
    SELECT
      userid,
      COUNT(*) AS total_comments_made
    FROM comments
    GROUP BY userid
  ),
  user_votes AS (
    SELECT
      userid,
      COUNT(*) AS total_votes_cast
    FROM votes
    GROUP BY userid
  ),
  user_badges AS (
    SELECT
      userid,
      COUNT(*) AS total_badges_earned
    FROM badges
    GROUP BY userid
  ),
  user_edits AS (
    SELECT
      userid,
      COUNT(*) AS total_edits_made
    FROM posthistory
    GROUP BY userid
  )
SELECT
  u.id AS user_id,
  u.reputation,
  COALESCE(up.total_posts, 0) AS total_posts,
  COALESCE(up.avg_post_score, 0) AS avg_post_score,
  COALESCE(up.total_views, 0) AS total_views,
  COALESCE(up.total_answers, 0) AS total_answers,
  COALESCE(up.total_comments_on_posts, 0) AS total_comments_on_posts,
  COALESCE(uc.total_comments_made, 0) AS total_comments_made,
  COALESCE(uv.total_votes_cast, 0) AS total_votes_cast,
  COALESCE(ub.total_badges_earned, 0) AS total_badges_earned,
  COALESCE(ue.total_edits_made, 0) AS total_edits_made
FROM users AS u
LEFT JOIN user_posts AS up ON up.userid = u.id
LEFT JOIN user_comments AS uc ON uc.userid = u.id
LEFT JOIN user_votes AS uv ON uv.userid = u.id
LEFT JOIN user_badges AS ub ON ub.userid = u.id
LEFT JOIN user_edits AS ue ON ue.userid = u.id
ORDER BY total_posts DESC
LIMIT 100
