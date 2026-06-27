WITH user_posts AS (
  SELECT
    owneruserid AS user_id,
    COUNT(*) AS post_count,
    COALESCE(SUM(score), 0) AS total_post_score,
    COALESCE(SUM(viewcount), 0) AS total_viewcount,
    COALESCE(SUM(answercount), 0) AS total_answer_count,
    COALESCE(SUM(commentcount), 0) AS total_comment_count
  FROM posts
  GROUP BY owneruserid
),
user_comments AS (
  SELECT
    userid AS user_id,
    COUNT(*) AS comment_count,
    COALESCE(SUM(score), 0) AS total_comment_score
  FROM comments
  GROUP BY userid
),
user_votes AS (
  SELECT
    userid AS user_id,
    COUNT(*) AS vote_count,
    SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
    SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count
  FROM votes
  GROUP BY userid
),
user_badges AS (
  SELECT
    userid AS user_id,
    COUNT(*) AS badge_count
  FROM badges
  GROUP BY userid
),
user_post_links AS (
  SELECT
    p.owneruserid AS user_id,
    COUNT(*) AS post_link_count
  FROM postlinks pl
  JOIN posts p ON pl.postid = p.id
  GROUP BY p.owneruserid
),
user_tags AS (
  SELECT
    p.owneruserid AS user_id,
    COUNT(*) AS tag_count
  FROM tags t
  JOIN posts p ON t.excerptpostid = p.id
  GROUP BY p.owneruserid
),
user_post_history AS (
  SELECT
    ph.userid AS user_id,
    COUNT(*) AS post_history_count,
    SUM(CASE WHEN ph.posthistorytypeid = 1 THEN 1 ELSE 0 END) AS edit_history_count
  FROM posthistory ph
  GROUP BY ph.userid
)
SELECT
  u.id AS user_id,
  u.reputation,
  u.creationdate,
  COALESCE(up.post_count, 0) AS post_count,
  COALESCE(up.total_post_score, 0) AS total_post_score,
  COALESCE(uc.comment_count, 0) AS comment_count,
  COALESCE(uc.total_comment_score, 0) AS total_comment_score,
  COALESCE(uv.vote_count, 0) AS vote_count,
  COALESCE(uv.upvote_count, 0) AS upvote_count,
  COALESCE(uv.downvote_count, 0) AS downvote_count,
  COALESCE(ub.badge_count, 0) AS badge_count,
  COALESCE(up_links.post_link_count, 0) AS post_link_count,
  COALESCE(ut.tag_count, 0) AS tag_count,
  COALESCE(uph.post_history_count, 0) AS post_history_count,
  COALESCE(uph.edit_history_count, 0) AS edit_history_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes uv ON uv.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_post_links up_links ON up_links.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
LEFT JOIN user_post_history uph ON uph.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
