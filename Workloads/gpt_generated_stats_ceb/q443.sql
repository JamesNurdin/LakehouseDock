/*
  Analytical query that summarizes activity per Stack Overflow user.
  It aggregates posts, comments, votes (cast and received), badges, tags, post‑history entries
  and post‑link counts, then ranks users by overall activity.
*/
WITH
  /* Posts created by each user */
  user_posts AS (
    SELECT
      owneruserid AS user_id,
      COUNT(*) AS post_count,
      COALESCE(SUM(score), 0) AS total_post_score,
      COALESCE(SUM(viewcount), 0) AS total_post_views,
      COALESCE(SUM(answercount), 0) AS total_answer_count,
      COALESCE(SUM(commentcount), 0) AS total_comment_on_posts,
      COALESCE(SUM(favoritecount), 0) AS total_favorite_count
    FROM posts
    GROUP BY owneruserid
  ),
  /* Comments written by each user */
  user_comments AS (
    SELECT
      userid AS user_id,
      COUNT(*) AS comment_count,
      COALESCE(SUM(score), 0) AS comment_score_sum
    FROM comments
    GROUP BY userid
  ),
  /* Votes cast by each user */
  user_votes_cast AS (
    SELECT
      userid AS user_id,
      COUNT(*) AS votes_cast,
      COALESCE(SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_cast,
      COALESCE(SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_cast
    FROM votes
    GROUP BY userid
  ),
  /* Votes received on posts owned by each user */
  user_votes_received AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(v.id) AS votes_received,
      COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvotes_received,
      COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvotes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id          -- allowed join rule
    GROUP BY p.owneruserid
  ),
  /* Badges earned by each user */
  user_badges AS (
    SELECT
      userid AS user_id,
      COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
  ),
  /* Tags attached to posts owned by each user */
  user_tags AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(*) AS tag_count,
      COALESCE(SUM(t.count), 0) AS tag_usage_sum
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id   -- allowed join rule
    GROUP BY p.owneruserid
  ),
  /* Post‑history entries performed by each user */
  user_posthistory AS (
    SELECT
      userid AS user_id,
      COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
  ),
  /* Post‑links originating from posts owned by each user */
  user_postlinks AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(*) AS postlink_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id        -- allowed join rule
    GROUP BY p.owneruserid
  )
SELECT
  u.id,
  u.reputation,
  COALESCE(up.post_count, 0)               AS post_count,
  COALESCE(up.total_post_score, 0)         AS total_post_score,
  COALESCE(up.total_post_views, 0)         AS total_post_views,
  COALESCE(up.total_answer_count, 0)      AS total_answer_count,
  COALESCE(up.total_comment_on_posts, 0)  AS total_comment_on_posts,
  COALESCE(up.total_favorite_count, 0)    AS total_favorite_count,
  COALESCE(uc.comment_count, 0)            AS comment_count,
  COALESCE(uc.comment_score_sum, 0)        AS comment_score_sum,
  COALESCE(uvc.votes_cast, 0)              AS votes_cast,
  COALESCE(uvc.upvote_cast, 0)             AS upvote_cast,
  COALESCE(uvc.downvote_cast, 0)           AS downvote_cast,
  COALESCE(uvr.votes_received, 0)          AS votes_received,
  COALESCE(uvr.upvotes_received, 0)        AS upvotes_received,
  COALESCE(uvr.downvotes_received, 0)      AS downvotes_received,
  COALESCE(ub.badge_count, 0)              AS badge_count,
  COALESCE(ut.tag_count, 0)                AS tag_count,
  COALESCE(ut.tag_usage_sum, 0)            AS tag_usage_sum,
  COALESCE(uph.posthistory_count, 0)      AS posthistory_count,
  COALESCE(ul.postlink_count, 0)           AS postlink_count,
  -- Simple activity score: weighted sum of the key metrics
  (COALESCE(up.post_count, 0) * 5 +
   COALESCE(uc.comment_count, 0) * 2 +
   COALESCE(uvc.votes_cast, 0) * 1 +
   COALESCE(uvr.votes_received, 0) * 1 +
   COALESCE(ub.badge_count, 0) * 3)      AS activity_score
FROM users u
LEFT JOIN user_posts        up  ON u.id = up.user_id
LEFT JOIN user_comments     uc  ON u.id = uc.user_id
LEFT JOIN user_votes_cast   uvc ON u.id = uvc.user_id
LEFT JOIN user_votes_received uvr ON u.id = uvr.user_id
LEFT JOIN user_badges       ub  ON u.id = ub.user_id
LEFT JOIN user_tags         ut  ON u.id = ut.user_id
LEFT JOIN user_posthistory  uph ON u.id = uph.user_id
LEFT JOIN user_postlinks    ul  ON u.id = ul.user_id
ORDER BY activity_score DESC
LIMIT 20
