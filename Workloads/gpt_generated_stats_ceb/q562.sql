WITH user_posts AS (
  SELECT u.id AS user_id,
         COUNT(p.id) AS post_count,
         COALESCE(SUM(p.score), 0) AS total_post_score,
         COALESCE(SUM(p.viewcount), 0) AS total_views,
         COALESCE(SUM(p.answercount), 0) AS total_answers,
         COALESCE(SUM(p.commentcount), 0) AS total_comments_on_posts,
         COALESCE(SUM(p.favoritecount), 0) AS total_favorites
  FROM users u
  LEFT JOIN posts p ON p.owneruserid = u.id
  GROUP BY u.id
),
user_comments AS (
  SELECT u.id AS user_id,
         COUNT(c.id) AS comment_count,
         COALESCE(AVG(c.score), 0) AS avg_comment_score,
         COALESCE(SUM(c.score), 0) AS total_comment_score
  FROM users u
  LEFT JOIN comments c ON c.userid = u.id
  GROUP BY u.id
),
user_badges AS (
  SELECT u.id AS user_id,
         COUNT(b.id) AS badge_count
  FROM users u
  LEFT JOIN badges b ON b.userid = u.id
  GROUP BY u.id
),
user_votes AS (
  SELECT u.id AS user_id,
         COUNT(v.id) AS vote_count,
         COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvote_count,
         COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvote_count,
         COALESCE(SUM(v.bountyamount), 0) AS total_bounty_amount
  FROM users u
  LEFT JOIN votes v ON v.userid = u.id
  GROUP BY u.id
)
SELECT u.id,
       u.reputation,
       u.upvotes,
       u.downvotes,
       up.post_count,
       up.total_post_score,
       up.total_views,
       up.total_answers,
       up.total_comments_on_posts,
       up.total_favorites,
       uc.comment_count,
       uc.avg_comment_score,
       uc.total_comment_score,
       ub.badge_count,
       uv.vote_count,
       uv.upvote_count,
       uv.downvote_count,
       uv.total_bounty_amount
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_votes uv ON uv.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
