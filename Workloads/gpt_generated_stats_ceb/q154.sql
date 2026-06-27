WITH
  user_badges AS (
    SELECT
      userid,
      COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
  ),
  user_votes_cast AS (
    SELECT
      userid,
      COUNT(*) AS votes_cast
    FROM votes
    GROUP BY userid
  ),
  user_comments AS (
    SELECT
      userid,
      COUNT(*) AS comment_count,
      SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY userid
  ),
  user_edits AS (
    SELECT
      userid,
      COUNT(*) AS edit_count
    FROM posthistory
    GROUP BY userid
  ),
  user_posts AS (
    SELECT
      owneruserid AS user_id,
      COUNT(*) AS post_count,
      SUM(score) AS total_score,
      AVG(score) AS avg_score,
      SUM(viewcount) AS total_viewcount,
      AVG(viewcount) AS avg_viewcount,
      SUM(answercount) AS total_answercount,
      SUM(favoritecount) AS total_favoritecount,
      SUM(commentcount) AS total_commentcount
    FROM posts
    GROUP BY owneruserid
  ),
  user_votes_received AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(v.id) AS votes_received,
      COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS upvotes_received,
      COUNT(CASE WHEN v.votetypeid = 3 THEN 1 END) AS downvotes_received
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
  ),
  user_tag_excerpts AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(DISTINCT t.id) AS distinct_tag_excerpt_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
  )
SELECT
  u.id AS user_id,
  u.reputation,
  u.creationdate,
  COALESCE(up.post_count, 0) AS total_posts,
  COALESCE(up.total_score, 0) AS total_post_score,
  COALESCE(up.avg_score, 0) AS avg_post_score,
  COALESCE(up.total_viewcount, 0) AS total_viewcount,
  COALESCE(up.avg_viewcount, 0) AS avg_viewcount,
  COALESCE(up.total_answercount, 0) AS total_answercount,
  COALESCE(up.total_favoritecount, 0) AS total_favoritecount,
  COALESCE(up.total_commentcount, 0) AS total_commentcount,
  COALESCE(uc.comment_count, 0) AS total_comments_made,
  COALESCE(uc.comment_score_sum, 0) AS total_comment_score,
  COALESCE(uvc.votes_cast, 0) AS total_votes_cast,
  COALESCE(uvr.votes_received, 0) AS total_votes_received,
  COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
  COALESCE(uvr.downvotes_received, 0) AS downvotes_received,
  COALESCE(ub.badge_count, 0) AS total_badges,
  COALESCE(ue.edit_count, 0) AS total_edits_made,
  COALESCE(ut.distinct_tag_excerpt_count, 0) AS distinct_tag_excerpts_owned
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_edits ue ON ue.userid = u.id
LEFT JOIN user_tag_excerpts ut ON ut.user_id = u.id
ORDER BY total_badges DESC, total_posts DESC
LIMIT 100
