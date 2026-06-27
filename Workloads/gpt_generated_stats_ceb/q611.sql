WITH user_base AS (
  SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate AS user_creationdate,
    COUNT(DISTINCT b.id) AS badge_count,
    COUNT(DISTINCT p.id) AS post_count,
    COALESCE(SUM(p.score), 0) AS total_post_score,
    COALESCE(AVG(p.answercount), 0) AS avg_answer_count,
    COUNT(DISTINCT c.id) AS comment_count,
    COALESCE(SUM(c.score), 0) AS total_comment_score,
    COUNT(DISTINCT v.id) AS vote_count,
    COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvote_count,
    COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvote_count
  FROM users u
  LEFT JOIN badges b ON b.userid = u.id
  LEFT JOIN posts p ON p.owneruserid = u.id
  LEFT JOIN comments c ON c.userid = u.id
  LEFT JOIN votes v ON v.userid = u.id
  GROUP BY u.id, u.reputation, u.creationdate
),
user_tag_counts AS (
  SELECT
    u.id AS user_id,
    COUNT(DISTINCT t.id) AS tag_count
  FROM users u
  LEFT JOIN posts p ON p.owneruserid = u.id
  LEFT JOIN tags t ON t.excerptpostid = p.id
  GROUP BY u.id
)
SELECT
  ub.user_id,
  ub.reputation,
  ub.badge_count,
  ub.post_count,
  ub.total_post_score,
  ub.avg_answer_count,
  ub.comment_count,
  ub.total_comment_score,
  ub.vote_count,
  ub.upvote_count,
  ub.downvote_count,
  COALESCE(utc.tag_count, 0) AS tag_count
FROM user_base ub
LEFT JOIN user_tag_counts utc ON utc.user_id = ub.user_id
ORDER BY ub.total_post_score DESC
LIMIT 10
