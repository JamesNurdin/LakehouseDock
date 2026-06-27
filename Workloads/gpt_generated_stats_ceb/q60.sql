WITH user_posts AS (
  SELECT
    owneruserid AS userid,
    COUNT(*) AS post_count,
    SUM(score) AS total_post_score,
    SUM(viewcount) AS total_view_count,
    SUM(answercount) AS total_answer_count,
    SUM(commentcount) AS total_comment_count,
    SUM(favoritecount) AS total_favorite_count
  FROM posts
  GROUP BY owneruserid
),
user_edits AS (
  SELECT
    lasteditoruserid AS userid,
    COUNT(*) AS edit_count
  FROM posts
  GROUP BY lasteditoruserid
),
user_comments AS (
  SELECT
    userid,
    COUNT(*) AS comment_count,
    SUM(score) AS total_comment_score
  FROM comments
  GROUP BY userid
),
user_votes_cast AS (
  SELECT
    userid,
    COUNT(*) AS votes_cast_count
  FROM votes
  GROUP BY userid
),
user_votes_received AS (
  SELECT
    p.owneruserid AS userid,
    COUNT(v.id) AS votes_received_count,
    SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_received_count,
    SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_received_count
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
user_posthistory AS (
  SELECT
    userid,
    COUNT(*) AS posthistory_count
  FROM posthistory
  GROUP BY userid
),
user_tags AS (
  SELECT
    p.owneruserid AS userid,
    COUNT(DISTINCT t.id) AS distinct_tag_count
  FROM posts p
  JOIN tags t ON t.excerptpostid = p.id
  GROUP BY p.owneruserid
),
user_postlinks AS (
  SELECT
    p.owneruserid AS userid,
    COUNT(pl.id) AS postlink_count
  FROM postlinks pl
  JOIN posts p ON pl.postid = p.id
  GROUP BY p.owneruserid
)
SELECT
  u.id AS user_id,
  u.reputation,
  COALESCE(up.post_count, 0) AS post_count,
  COALESCE(up.total_post_score, 0) AS total_post_score,
  COALESCE(ue.edit_count, 0) AS edit_count,
  COALESCE(uc.comment_count, 0) AS comment_count,
  COALESCE(uc.total_comment_score, 0) AS total_comment_score,
  COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
  COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
  COALESCE(ub.badge_count, 0) AS badge_count,
  COALESCE(uph.posthistory_count, 0) AS posthistory_count,
  COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count,
  COALESCE(upL.postlink_count, 0) AS postlink_count,
  (
    u.reputation * 0.1
    + COALESCE(up.total_post_score, 0) * 0.5
    + COALESCE(uc.total_comment_score, 0) * 0.3
    + COALESCE(uvr.votes_received_count, 0) * 0.2
    + COALESCE(ub.badge_count, 0) * 5
    + COALESCE(uph.posthistory_count, 0) * 0.1
    + COALESCE(ut.distinct_tag_count, 0) * 2
    + COALESCE(upL.postlink_count, 0) * 0.5
  ) AS contribution_score
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_edits ue ON ue.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
LEFT JOIN user_tags ut ON ut.userid = u.id
LEFT JOIN user_postlinks upL ON upL.userid = u.id
ORDER BY contribution_score DESC
LIMIT 10
