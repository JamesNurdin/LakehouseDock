WITH user_posts AS (
  SELECT
    p.owneruserid AS userid,
    COUNT(*) AS post_count,
    SUM(p.score) AS total_post_score,
    SUM(p.viewcount) AS total_view_count,
    SUM(p.answercount) AS total_answer_count,
    SUM(p.commentcount) AS total_comment_count,
    SUM(p.favoritecount) AS total_favorite_count
  FROM posts p
  GROUP BY p.owneruserid
),
user_comments AS (
  SELECT
    c.userid,
    COUNT(*) AS comment_count,
    AVG(c.score) AS avg_comment_score
  FROM comments c
  GROUP BY c.userid
),
user_votes_cast AS (
  SELECT
    v.userid,
    COUNT(*) AS votes_cast,
    SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
    SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
  FROM votes v
  GROUP BY v.userid
),
user_votes_received AS (
  SELECT
    p.owneruserid AS userid,
    COUNT(*) AS votes_received,
    SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
    SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
  FROM votes v
  JOIN posts p ON v.postid = p.id
  GROUP BY p.owneruserid
),
user_badges AS (
  SELECT
    b.userid,
    COUNT(*) AS badge_count
  FROM badges b
  GROUP BY b.userid
),
user_tags AS (
  SELECT
    p.owneruserid AS userid,
    COUNT(DISTINCT t.id) AS distinct_tag_count
  FROM posts p
  JOIN tags t ON t.excerptpostid = p.id
  GROUP BY p.owneruserid
),
user_edits AS (
  SELECT
    ph.userid,
    COUNT(*) AS edit_count,
    COUNT(DISTINCT ph.postid) AS distinct_posts_edited
  FROM posthistory ph
  GROUP BY ph.userid
),
user_postlinks AS (
  SELECT
    p.owneruserid AS userid,
    COUNT(*) AS postlink_count
  FROM postlinks pl
  JOIN posts p ON pl.postid = p.id
  GROUP BY p.owneruserid
)

SELECT
  u.id AS user_id,
  u.reputation,
  u.creationdate,
  COALESCE(up.post_count, 0) AS post_count,
  COALESCE(up.total_post_score, 0) AS total_post_score,
  COALESCE(up.total_view_count, 0) AS total_view_count,
  COALESCE(up.total_answer_count, 0) AS total_answer_count,
  COALESCE(up.total_comment_count, 0) AS total_comment_count,
  COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
  COALESCE(uc.comment_count, 0) AS comment_count,
  COALESCE(uc.avg_comment_score, 0.0) AS avg_comment_score,
  COALESCE(uvc.votes_cast, 0) AS votes_cast,
  COALESCE(uvc.upvotes_cast, 0) AS upvotes_cast,
  COALESCE(uvc.downvotes_cast, 0) AS downvotes_cast,
  COALESCE(uvr.votes_received, 0) AS votes_received,
  COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
  COALESCE(uvr.downvotes_received, 0) AS downvotes_received,
  COALESCE(ub.badge_count, 0) AS badge_count,
  COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count,
  COALESCE(ue.edit_count, 0) AS edit_count,
  COALESCE(ue.distinct_posts_edited, 0) AS distinct_posts_edited,
  COALESCE(upln.postlink_count, 0) AS postlink_count
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_tags ut ON ut.userid = u.id
LEFT JOIN user_edits ue ON ue.userid = u.id
LEFT JOIN user_postlinks upln ON upln.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
