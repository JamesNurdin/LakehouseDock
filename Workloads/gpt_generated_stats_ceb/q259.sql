WITH user_posts AS (
  SELECT
    owneruserid,
    COUNT(*) AS post_count,
    SUM(score) AS total_post_score,
    AVG(score) AS avg_post_score,
    SUM(viewcount) AS total_viewcount,
    SUM(answercount) AS total_answercount,
    SUM(favoritecount) AS total_favoritecount
  FROM posts
  GROUP BY owneruserid
),
user_votes AS (
  SELECT
    userid,
    COUNT(*) AS vote_count,
    COUNT(DISTINCT postid) AS distinct_posts_voted,
    SUM(COALESCE(bountyamount, 0)) AS total_bounty_amount
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
user_comments AS (
  SELECT
    userid,
    COUNT(*) AS comment_count,
    AVG(score) AS avg_comment_score,
    SUM(score) AS total_comment_score
  FROM comments
  GROUP BY userid
)
SELECT
  u.id AS user_id,
  u.reputation,
  u.creationdate,
  u.views,
  u.upvotes,
  u.downvotes,
  COALESCE(up.post_count, 0) AS post_count,
  COALESCE(up.total_post_score, 0) AS total_post_score,
  COALESCE(up.avg_post_score, 0) AS avg_post_score,
  COALESCE(up.total_viewcount, 0) AS total_viewcount,
  COALESCE(up.total_answercount, 0) AS total_answercount,
  COALESCE(up.total_favoritecount, 0) AS total_favoritecount,
  COALESCE(v.vote_count, 0) AS vote_count,
  COALESCE(v.distinct_posts_voted, 0) AS distinct_posts_voted,
  COALESCE(v.total_bounty_amount, 0) AS total_bounty_amount,
  COALESCE(b.badge_count, 0) AS badge_count,
  COALESCE(c.comment_count, 0) AS comment_count,
  COALESCE(c.avg_comment_score, 0) AS avg_comment_score,
  COALESCE(c.total_comment_score, 0) AS total_comment_score,
  ROW_NUMBER() OVER (ORDER BY COALESCE(up.total_post_score, 0) DESC) AS user_rank
FROM users u
LEFT JOIN user_posts up ON up.owneruserid = u.id
LEFT JOIN user_votes v ON v.userid = u.id
LEFT JOIN user_badges b ON b.userid = u.id
LEFT JOIN user_comments c ON c.userid = u.id
ORDER BY total_post_score DESC
LIMIT 10
