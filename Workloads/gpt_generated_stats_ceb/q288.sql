WITH
  user_posts AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(*) AS post_count,
      COALESCE(SUM(p.score), 0) AS total_post_score,
      COALESCE(SUM(p.viewcount), 0) AS total_viewcount,
      COALESCE(SUM(p.answercount), 0) AS total_answercount
    FROM posts p
    GROUP BY p.owneruserid
  ),
  user_comments AS (
    SELECT
      c.userid AS user_id,
      COUNT(*) AS comment_count,
      COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
  ),
  user_votes_cast AS (
    SELECT
      v.userid AS user_id,
      COUNT(*) AS vote_cast_count,
      COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS upvote_cast,
      COUNT(CASE WHEN v.votetypeid = 3 THEN 1 END) AS downvote_cast
    FROM votes v
    GROUP BY v.userid
  ),
  user_badges AS (
    SELECT
      b.userid AS user_id,
      COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
  ),
  user_posthistory AS (
    SELECT
      ph.userid AS user_id,
      COUNT(*) AS post_history_count
    FROM posthistory ph
    GROUP BY ph.userid
  ),
  user_postlinks AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(DISTINCT pl.id) AS post_link_count
    FROM posts p
    JOIN postlinks pl ON pl.postid = p.id
    GROUP BY p.owneruserid
  ),
  user_tags AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(*) AS tag_association_count,
      COALESCE(SUM(t.count), 0) AS total_tag_usage
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
  )
SELECT
  u.id AS user_id,
  u.reputation,
  COALESCE(up.post_count, 0) AS post_count,
  COALESCE(up.total_post_score, 0) AS total_post_score,
  COALESCE(up.total_viewcount, 0) AS total_viewcount,
  COALESCE(up.total_answercount, 0) AS total_answercount,
  COALESCE(uc.comment_count, 0) AS comment_count,
  COALESCE(uc.total_comment_score, 0) AS total_comment_score,
  COALESCE(uv.vote_cast_count, 0) AS vote_cast_count,
  COALESCE(uv.upvote_cast, 0) AS upvote_cast,
  COALESCE(uv.downvote_cast, 0) AS downvote_cast,
  COALESCE(ub.badge_count, 0) AS badge_count,
  COALESCE(uph.post_history_count, 0) AS post_history_count,
  COALESCE(upl.post_link_count, 0) AS post_link_count,
  COALESCE(ut.tag_association_count, 0) AS tag_association_count,
  COALESCE(ut.total_tag_usage, 0) AS total_tag_usage
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uv ON uv.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_postlinks upl ON upl.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 100
