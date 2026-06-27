WITH
  user_basic AS (
    SELECT
      id AS user_id,
      reputation,
      creationdate,
      views,
      upvotes,
      downvotes
    FROM users
  ),
  user_posts AS (
    SELECT
      owneruserid AS user_id,
      COUNT(*) AS post_count,
      COALESCE(SUM(score), 0) AS total_post_score,
      COALESCE(AVG(viewcount), 0) AS avg_viewcount,
      COALESCE(SUM(answercount), 0) AS total_answer_count,
      COALESCE(SUM(commentcount), 0) AS total_comment_on_posts,
      COALESCE(SUM(favoritecount), 0) AS total_favorite_count
    FROM posts
    GROUP BY owneruserid
  ),
  user_edits AS (
    SELECT
      lasteditoruserid AS user_id,
      COUNT(*) AS edit_count
    FROM posts
    WHERE lasteditoruserid IS NOT NULL
    GROUP BY lasteditoruserid
  ),
  user_comments AS (
    SELECT
      userid AS user_id,
      COUNT(*) AS comment_count,
      COALESCE(SUM(score), 0) AS total_comment_score
    FROM comments
    GROUP BY userid
  ),
  user_votes_cast AS (
    SELECT
      userid AS user_id,
      COUNT(*) AS votes_cast,
      SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
      SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM votes
    GROUP BY userid
  ),
  user_votes_received AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(*) AS votes_received,
      SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
      SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
  ),
  user_badges AS (
    SELECT
      userid AS user_id,
      COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
  ),
  user_posthistory AS (
    SELECT
      userid AS user_id,
      COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
  ),
  user_postlinks AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(*) AS post_links_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
  )
SELECT
  ub.user_id,
  ub.reputation,
  COALESCE(up.post_count, 0) AS post_count,
  COALESCE(up.total_post_score, 0) AS total_post_score,
  COALESCE(up.avg_viewcount, 0) AS avg_viewcount,
  COALESCE(uc.comment_count, 0) AS comment_count,
  COALESCE(uc.total_comment_score, 0) AS total_comment_score,
  COALESCE(uvc.votes_cast, 0) AS votes_cast,
  COALESCE(uvc.upvotes_cast, 0) AS upvotes_cast,
  COALESCE(uvc.downvotes_cast, 0) AS downvotes_cast,
  COALESCE(uvr.votes_received, 0) AS votes_received,
  COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
  COALESCE(uvr.downvotes_received, 0) AS downvotes_received,
  COALESCE(ubdg.badge_count, 0) AS badge_count,
  COALESCE(uph.posthistory_count, 0) AS posthistory_count,
  COALESCE(ue.edit_count, 0) AS edit_count,
  COALESCE(ul.post_links_count, 0) AS post_links_count
FROM user_basic ub
LEFT JOIN user_posts up ON up.user_id = ub.user_id
LEFT JOIN user_edits ue ON ue.user_id = ub.user_id
LEFT JOIN user_comments uc ON uc.user_id = ub.user_id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = ub.user_id
LEFT JOIN user_votes_received uvr ON uvr.user_id = ub.user_id
LEFT JOIN user_badges ubdg ON ubdg.user_id = ub.user_id
LEFT JOIN user_posthistory uph ON uph.user_id = ub.user_id
LEFT JOIN user_postlinks ul ON ul.user_id = ub.user_id
ORDER BY post_count DESC
LIMIT 50
