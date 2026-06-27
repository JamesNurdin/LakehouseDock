WITH user_posts AS (
  SELECT
    owneruserid AS user_id,
    COUNT(*) AS total_posts_owned,
    AVG(score) AS avg_post_score_owned,
    AVG(viewcount) AS avg_post_viewcount_owned,
    SUM(CASE WHEN answercount > 0 THEN 1 ELSE 0 END) AS posts_with_answers
  FROM posts
  GROUP BY owneruserid
),
user_last_edits AS (
  SELECT
    lasteditoruserid AS user_id,
    COUNT(*) AS total_posts_last_edited
  FROM posts
  GROUP BY lasteditoruserid
),
user_comments AS (
  SELECT
    userid AS user_id,
    COUNT(*) AS total_comments_made
  FROM comments
  GROUP BY userid
),
user_votes AS (
  SELECT
    userid AS user_id,
    COUNT(*) AS total_votes_cast
  FROM votes
  GROUP BY userid
),
user_badges AS (
  SELECT
    userid AS user_id,
    COUNT(*) AS total_badges_earned
  FROM badges
  GROUP BY userid
),
user_posthistory AS (
  SELECT
    userid AS user_id,
    COUNT(*) AS total_posthistory_events
  FROM posthistory
  GROUP BY userid
),
user_postlinks AS (
  SELECT
    p.owneruserid AS user_id,
    COUNT(*) AS total_postlinks_created
  FROM postlinks pl
  JOIN posts p ON pl.postid = p.id
  GROUP BY p.owneruserid
),
user_received_votes AS (
  SELECT
    p.owneruserid AS user_id,
    COUNT(*) AS total_votes_received,
    SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
    SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
  FROM votes v
  JOIN posts p ON v.postid = p.id
  GROUP BY p.owneruserid
)
SELECT
  u.id AS user_id,
  u.reputation,
  COALESCE(p.total_posts_owned, 0) AS total_posts_owned,
  COALESCE(p.posts_with_answers, 0) AS posts_with_answers,
  CASE WHEN COALESCE(p.total_posts_owned, 0) = 0 THEN 0
       ELSE CAST(COALESCE(p.posts_with_answers, 0) AS double) / COALESCE(p.total_posts_owned, 1)
  END AS answer_ratio,
  COALESCE(p.avg_post_score_owned, 0) AS avg_post_score_owned,
  COALESCE(p.avg_post_viewcount_owned, 0) AS avg_post_viewcount_owned,
  COALESCE(e.total_posts_last_edited, 0) AS total_posts_last_edited,
  COALESCE(c.total_comments_made, 0) AS total_comments_made,
  COALESCE(v.total_votes_cast, 0) AS total_votes_cast,
  COALESCE(b.total_badges_earned, 0) AS total_badges_earned,
  COALESCE(h.total_posthistory_events, 0) AS total_posthistory_events,
  COALESCE(l.total_postlinks_created, 0) AS total_postlinks_created,
  COALESCE(rv.total_votes_received, 0) AS total_votes_received,
  COALESCE(rv.upvotes_received, 0) AS upvotes_received,
  COALESCE(rv.downvotes_received, 0) AS downvotes_received,
  CASE WHEN COALESCE(rv.total_votes_received, 0) = 0 THEN 0
       ELSE CAST(COALESCE(rv.upvotes_received, 0) AS double) / COALESCE(rv.total_votes_received, 1)
  END AS upvote_ratio_received
FROM users u
LEFT JOIN user_posts p ON p.user_id = u.id
LEFT JOIN user_last_edits e ON e.user_id = u.id
LEFT JOIN user_comments c ON c.user_id = u.id
LEFT JOIN user_votes v ON v.user_id = u.id
LEFT JOIN user_badges b ON b.user_id = u.id
LEFT JOIN user_posthistory h ON h.user_id = u.id
LEFT JOIN user_postlinks l ON l.user_id = u.id
LEFT JOIN user_received_votes rv ON rv.user_id = u.id
ORDER BY answer_ratio DESC, upvote_ratio_received DESC
LIMIT 100
