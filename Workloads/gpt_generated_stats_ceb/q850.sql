WITH
  user_posts AS (
    SELECT
      owneruserid AS user_id,
      COUNT(*) AS post_count,
      SUM(score) AS total_post_score,
      AVG(score) AS avg_post_score,
      SUM(viewcount) AS total_viewcount,
      COUNT(CASE WHEN posttypeid = 1 THEN 1 END) AS question_count,
      COUNT(CASE WHEN posttypeid = 2 THEN 1 END) AS answer_count
    FROM posts
    GROUP BY owneruserid
  ),
  user_comments_made AS (
    SELECT
      userid AS user_id,
      COUNT(*) AS comment_made_count
    FROM comments
    GROUP BY userid
  ),
  user_comments_received AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(c.id) AS comment_received_count
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY p.owneruserid
  ),
  user_votes_received AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(v.id) AS votes_received_count,
      SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_received_count,
      SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_received_count
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
  ),
  user_votes_cast AS (
    SELECT
      userid AS user_id,
      COUNT(*) AS votes_cast_count
    FROM votes
    GROUP BY userid
  ),
  user_badges AS (
    SELECT
      userid AS user_id,
      COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
  ),
  user_tags AS (
    SELECT
      p.owneruserid AS user_id,
      COUNT(DISTINCT t.id) AS distinct_tag_excerpt_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
  )
SELECT
  u.id,
  u.reputation,
  RANK() OVER (ORDER BY u.reputation DESC) AS reputation_rank,
  COALESCE(up.post_count, 0) AS total_posts,
  COALESCE(up.question_count, 0) AS total_questions,
  COALESCE(up.answer_count, 0) AS total_answers,
  COALESCE(up.total_post_score, 0) AS total_post_score,
  COALESCE(up.avg_post_score, 0) AS avg_post_score,
  COALESCE(cm.comment_made_count, 0) AS comments_made,
  COALESCE(cr.comment_received_count, 0) AS comments_received,
  COALESCE(vr.votes_received_count, 0) AS votes_received,
  COALESCE(vr.upvote_received_count, 0) AS upvotes_received,
  COALESCE(vr.downvote_received_count, 0) AS downvotes_received,
  COALESCE(vc.votes_cast_count, 0) AS votes_cast,
  COALESCE(b.badge_count, 0) AS badge_count,
  COALESCE(tg.distinct_tag_excerpt_count, 0) AS distinct_tag_excerpts
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments_made cm ON cm.user_id = u.id
LEFT JOIN user_comments_received cr ON cr.user_id = u.id
LEFT JOIN user_votes_received vr ON vr.user_id = u.id
LEFT JOIN user_votes_cast vc ON vc.user_id = u.id
LEFT JOIN user_badges b ON b.user_id = u.id
LEFT JOIN user_tags tg ON tg.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
