WITH
  user_posts AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(*) AS post_count,
      SUM(p.score) AS total_post_score,
      AVG(p.score) AS avg_post_score,
      SUM(p.viewcount) AS total_post_views,
      SUM(p.answercount) AS total_answer_count,
      SUM(p.commentcount) AS total_comment_count,
      SUM(p.favoritecount) AS total_favorite_count
    FROM posts p
    GROUP BY p.owneruserid
  ),
  user_comments AS (
    SELECT
      c.userid AS user_id,
      COUNT(*) AS comment_count,
      SUM(c.score) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
  ),
  user_votes_cast AS (
    SELECT
      v.userid AS user_id,
      COUNT(*) AS votes_cast_count
    FROM votes v
    GROUP BY v.userid
  ),
  user_votes_received AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(*) AS votes_received_count
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
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
      COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
  )
SELECT
  u.id AS user_id,
  u.reputation,
  COALESCE(up.post_count, 0)               AS total_posts,
  COALESCE(up.total_post_score, 0)         AS total_post_score,
  COALESCE(up.avg_post_score, 0)           AS avg_post_score,
  COALESCE(up.total_post_views, 0)         AS total_post_views,
  COALESCE(up.total_answer_count, 0)      AS total_answers,
  COALESCE(up.total_comment_count, 0)     AS total_post_comments,
  COALESCE(up.total_favorite_count, 0)    AS total_favorites,
  COALESCE(uc.comment_count, 0)            AS total_comments_made,
  COALESCE(uc.total_comment_score, 0)     AS total_comment_score,
  COALESCE(uvc.votes_cast_count, 0)        AS total_votes_cast,
  COALESCE(uvr.votes_received_count, 0)    AS total_votes_received,
  COALESCE(ub.badge_count, 0)              AS total_badges,
  COALESCE(uph.posthistory_count, 0)       AS total_posthistory_events
FROM users u
LEFT JOIN user_posts up          ON up.user_id = u.id
LEFT JOIN user_comments uc       ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc    ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub         ON ub.user_id = u.id
LEFT JOIN user_posthistory uph   ON uph.user_id = u.id
WHERE COALESCE(up.post_count, 0) >= 10
ORDER BY total_post_score DESC
LIMIT 10
