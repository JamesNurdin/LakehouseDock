WITH user_posts AS (
  SELECT owneruserid AS user_id,
         COUNT(*) AS post_count,
         SUM(score) AS post_score_sum,
         AVG(score) AS post_score_avg,
         COUNT(CASE WHEN posttypeid = 2 THEN 1 END) AS answer_count,
         COUNT(CASE WHEN posttypeid = 1 THEN 1 END) AS question_count
  FROM posts
  GROUP BY owneruserid
),
user_comments AS (
  SELECT userid AS user_id,
         COUNT(*) AS comment_count,
         SUM(score) AS comment_score_sum,
         AVG(score) AS comment_score_avg
  FROM comments
  GROUP BY userid
),
user_votes AS (
  SELECT userid AS user_id,
         COUNT(*) AS vote_cast_count,
         SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cast_count,
         SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cast_count
  FROM votes
  GROUP BY userid
),
user_badges AS (
  SELECT userid AS user_id,
         COUNT(*) AS badge_count
  FROM badges
  GROUP BY userid
),
user_history AS (
  SELECT userid AS user_id,
         COUNT(*) AS posthistory_count
  FROM posthistory
  GROUP BY userid
),
user_tags AS (
  SELECT p.owneruserid AS user_id,
         COUNT(DISTINCT t.id) AS distinct_tag_count
  FROM posts p
  JOIN tags t ON t.excerptpostid = p.id
  GROUP BY p.owneruserid
),
user_postlinks AS (
  SELECT p.owneruserid AS user_id,
         COUNT(*) AS postlink_count
  FROM posts p
  JOIN postlinks pl ON pl.postid = p.id
  GROUP BY p.owneruserid
),
user_posthistory_events AS (
  SELECT p.owneruserid AS user_id,
         COUNT(*) AS posthistory_event_count
  FROM posts p
  JOIN posthistory ph ON ph.posthistorytypeid = p.id
  GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(p.post_count, 0) AS post_count,
       COALESCE(p.post_score_sum, 0) AS post_score_sum,
       COALESCE(p.post_score_avg, 0) AS post_score_avg,
       COALESCE(p.answer_count, 0) AS answer_count,
       COALESCE(p.question_count, 0) AS question_count,
       COALESCE(c.comment_count, 0) AS comment_count,
       COALESCE(c.comment_score_sum, 0) AS comment_score_sum,
       COALESCE(c.comment_score_avg, 0) AS comment_score_avg,
       COALESCE(v.vote_cast_count, 0) AS vote_cast_count,
       COALESCE(v.upvote_cast_count, 0) AS upvote_cast_count,
       COALESCE(v.downvote_cast_count, 0) AS downvote_cast_count,
       COALESCE(b.badge_count, 0) AS badge_count,
       COALESCE(h.posthistory_count, 0) AS posthistory_user_count,
       COALESCE(t.distinct_tag_count, 0) AS distinct_tag_count,
       COALESCE(pl.postlink_count, 0) AS postlink_count,
       COALESCE(pe.posthistory_event_count, 0) AS posthistory_event_count
FROM users u
LEFT JOIN user_posts p ON p.user_id = u.id
LEFT JOIN user_comments c ON c.user_id = u.id
LEFT JOIN user_votes v ON v.user_id = u.id
LEFT JOIN user_badges b ON b.user_id = u.id
LEFT JOIN user_history h ON h.user_id = u.id
LEFT JOIN user_tags t ON t.user_id = u.id
LEFT JOIN user_postlinks pl ON pl.user_id = u.id
LEFT JOIN user_posthistory_events pe ON pe.user_id = u.id
ORDER BY post_score_sum DESC
LIMIT 10
