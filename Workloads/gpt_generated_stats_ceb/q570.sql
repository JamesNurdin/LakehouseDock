WITH
  user_posts AS (
    SELECT
      p.owneruserid AS userid,
      COUNT(*) AS post_count,
      SUM(p.score) AS total_post_score,
      SUM(p.viewcount) AS total_post_views,
      SUM(p.answercount) AS total_answers,
      SUM(p.commentcount) AS total_post_comments,
      SUM(p.favoritecount) AS total_favorites
    FROM posts p
    GROUP BY p.owneruserid
  ),
  user_comments AS (
    SELECT
      c.userid,
      COUNT(*) AS comment_count,
      SUM(c.score) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
  ),
  user_votes_cast AS (
    SELECT
      v.userid,
      COUNT(*) AS votes_cast,
      COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvotes_cast,
      COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvotes_cast
    FROM votes v
    GROUP BY v.userid
  ),
  user_votes_received AS (
    SELECT
      p.owneruserid AS userid,
      COUNT(*) AS votes_received,
      COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvotes_received,
      COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvotes_received
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
  user_posthistory AS (
    SELECT
      ph.userid,
      COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
  ),
  user_tag_excerpts AS (
    SELECT
      p.owneruserid AS userid,
      COUNT(*) AS tag_excerpts_owned,
      SUM(t.count) AS total_tag_usage
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
  ),
  user_postlinks AS (
    SELECT
      p.owneruserid AS userid,
      COUNT(*) AS postlinks_owned
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
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
  COALESCE(up.total_post_views, 0) AS total_post_views,
  COALESCE(up.total_answers, 0) AS total_answers,
  COALESCE(up.total_post_comments, 0) AS total_post_comments,
  COALESCE(up.total_favorites, 0) AS total_favorites,
  COALESCE(uc.comment_count, 0) AS comment_count,
  COALESCE(uc.total_comment_score, 0) AS total_comment_score,
  COALESCE(uvc.votes_cast, 0) AS votes_cast,
  COALESCE(uvc.upvotes_cast, 0) AS upvotes_cast,
  COALESCE(uvc.downvotes_cast, 0) AS downvotes_cast,
  COALESCE(uvr.votes_received, 0) AS votes_received,
  COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
  COALESCE(uvr.downvotes_received, 0) AS downvotes_received,
  COALESCE(ub.badge_count, 0) AS badge_count,
  COALESCE(uph.posthistory_count, 0) AS posthistory_count,
  COALESCE(ute.tag_excerpts_owned, 0) AS tag_excerpts_owned,
  COALESCE(ute.total_tag_usage, 0) AS total_tag_usage,
  COALESCE(upk.postlinks_owned, 0) AS postlinks_owned
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
LEFT JOIN user_tag_excerpts ute ON ute.userid = u.id
LEFT JOIN user_postlinks upk ON upk.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
