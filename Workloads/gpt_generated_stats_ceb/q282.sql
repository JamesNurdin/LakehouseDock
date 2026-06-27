WITH
  user_badges AS (
    SELECT
      b.userid AS user_id,
      COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
  ),
  user_posts AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(*) AS post_count,
      COALESCE(SUM(p.score), 0) AS total_post_score
    FROM posts p
    GROUP BY p.owneruserid
  ),
  user_comments_made AS (
    SELECT
      c.userid AS user_id,
      COUNT(*) AS comment_made_count,
      COALESCE(SUM(c.score), 0) AS comment_score_made
    FROM comments c
    GROUP BY c.userid
  ),
  user_comment_score_received AS (
    SELECT
      p.owneruserid AS user_id,
      COALESCE(SUM(c.score), 0) AS comment_score_received,
      COUNT(c.id) AS comment_received_count
    FROM posts p
    LEFT JOIN comments c ON c.postid = p.id
    GROUP BY p.owneruserid
  ),
  user_votes_cast AS (
    SELECT
      v.userid AS user_id,
      COUNT(*) AS vote_cast_count
    FROM votes v
    GROUP BY v.userid
  ),
  user_votes_received AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(v.id) AS vote_received_count
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
  ),
  user_posthistory AS (
    SELECT
      ph.userid AS user_id,
      COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
  ),
  user_tags AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM posts p
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
  ),
  user_postlinks AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(pl.id) AS postlink_count
    FROM posts p
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY p.owneruserid
  )
SELECT
  u.id AS user_id,
  u.reputation,
  COALESCE(ub.badge_count, 0) AS badge_count,
  COALESCE(up.post_count, 0) AS post_count,
  COALESCE(up.total_post_score, 0) AS total_post_score,
  COALESCE(ucm.comment_made_count, 0) AS comment_made_count,
  COALESCE(ucm.comment_score_made, 0) AS comment_score_made,
  COALESCE(ucs.comment_score_received, 0) AS comment_score_received,
  COALESCE(ucs.comment_received_count, 0) AS comment_received_count,
  COALESCE(uvc.vote_cast_count, 0) AS vote_cast_count,
  COALESCE(uvr.vote_received_count, 0) AS vote_received_count,
  COALESCE(uph.posthistory_count, 0) AS posthistory_count,
  COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count,
  COALESCE(upk.postlink_count, 0) AS postlink_count,
  (u.reputation
   + COALESCE(ub.badge_count, 0) * 100
   + COALESCE(up.post_count, 0) * 10
   + COALESCE(uvc.vote_cast_count, 0) * 5
   + COALESCE(upk.postlink_count, 0) * 2) AS activity_score
FROM users u
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments_made ucm ON ucm.user_id = u.id
LEFT JOIN user_comment_score_received ucs ON ucs.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
LEFT JOIN user_postlinks upk ON upk.user_id = u.id
ORDER BY activity_score DESC
LIMIT 10
