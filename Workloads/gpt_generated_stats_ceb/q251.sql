/*
  Per‑user activity summary – combines posts, comments, votes (cast & received),
  badges, post‑history events and post‑link activity.  The result is ordered by a
  weighted activity_score and limited to the top 100 users.
*/
WITH
  user_posts AS (
    SELECT
      owneruserid AS userid,
      COUNT(*) AS post_count,
      SUM(score) AS total_post_score,
      AVG(score) AS avg_post_score,
      SUM(viewcount) AS total_viewcount,
      SUM(answercount) AS total_answercount,
      SUM(commentcount) AS total_commentcount,
      SUM(favoritecount) AS total_favoritecount
    FROM posts
    GROUP BY owneruserid
  ),
  user_comments AS (
    SELECT
      userid,
      COUNT(*) AS comment_count,
      SUM(score) AS total_comment_score,
      AVG(score) AS avg_comment_score
    FROM comments
    GROUP BY userid
  ),
  user_votes_cast AS (
    SELECT
      userid,
      COUNT(*) AS votes_cast,
      SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_cast,
      SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM votes
    GROUP BY userid
  ),
  user_votes_received AS (
    SELECT
      p.owneruserid AS userid,
      COUNT(*) AS votes_received,
      SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
      SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
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
      COUNT(*) AS posthistory_events
    FROM posthistory
    GROUP BY userid
  ),
  user_postlinks_created AS (
    SELECT
      p.owneruserid AS userid,
      COUNT(*) AS postlinks_created
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
  ),
  user_postlinks_related AS (
    SELECT
      p.owneruserid AS userid,
      COUNT(*) AS postlinks_related
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
  )
SELECT
  u.id AS user_id,
  u.reputation,
  u.creationdate,
  COALESCE(up.post_count, 0) AS post_count,
  COALESCE(up.total_post_score, 0) AS total_post_score,
  COALESCE(up.avg_post_score, 0) AS avg_post_score,
  COALESCE(up.total_viewcount, 0) AS total_viewcount,
  COALESCE(up.total_answercount, 0) AS total_answercount,
  COALESCE(up.total_commentcount, 0) AS total_post_comment_count,
  COALESCE(up.total_favoritecount, 0) AS total_favoritecount,
  COALESCE(uc.comment_count, 0) AS comment_count,
  COALESCE(uc.total_comment_score, 0) AS total_comment_score,
  COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
  COALESCE(vc.votes_cast, 0) AS votes_cast,
  COALESCE(vc.upvotes_cast, 0) AS upvotes_cast,
  COALESCE(vc.downvotes_cast, 0) AS downvotes_cast,
  COALESCE(vr.votes_received, 0) AS votes_received,
  COALESCE(vr.upvotes_received, 0) AS upvotes_received,
  COALESCE(vr.downvotes_received, 0) AS downvotes_received,
  COALESCE(b.badge_count, 0) AS badge_count,
  COALESCE(ph.posthistory_events, 0) AS posthistory_events,
  COALESCE(plc.postlinks_created, 0) AS postlinks_created,
  COALESCE(plr.postlinks_related, 0) AS postlinks_related,
  -- weighted activity score (higher weight for posts and badges)
  (COALESCE(up.post_count, 0) * 5
   + COALESCE(uc.comment_count, 0) * 2
   + COALESCE(vc.votes_cast, 0) * 1
   + COALESCE(vr.votes_received, 0) * 1
   + COALESCE(b.badge_count, 0) * 3
   + COALESCE(ph.posthistory_events, 0) * 1
   + COALESCE(plc.postlinks_created, 0) * 1
   + COALESCE(plr.postlinks_related, 0) * 1) AS activity_score
FROM users u
LEFT JOIN user_posts up ON u.id = up.userid
LEFT JOIN user_comments uc ON u.id = uc.userid
LEFT JOIN user_votes_cast vc ON u.id = vc.userid
LEFT JOIN user_votes_received vr ON u.id = vr.userid
LEFT JOIN user_badges b ON u.id = b.userid
LEFT JOIN user_posthistory ph ON u.id = ph.userid
LEFT JOIN user_postlinks_created plc ON u.id = plc.userid
LEFT JOIN user_postlinks_related plr ON u.id = plr.userid
ORDER BY activity_score DESC
LIMIT 100
