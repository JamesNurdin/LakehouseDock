WITH user_posts AS (
   SELECT
       p.owneruserid AS userid,
       COUNT(*) AS post_count,
       COALESCE(SUM(p.score), 0) AS total_post_score,
       COALESCE(AVG(p.viewcount), 0) AS avg_view_count,
       COALESCE(SUM(p.answercount), 0) AS total_answers,
       COALESCE(SUM(p.commentcount), 0) AS total_comments_on_posts,
       COALESCE(SUM(p.favoritecount), 0) AS total_favorites
   FROM posts p
   GROUP BY p.owneruserid
),
user_comments AS (
   SELECT
       c.userid AS userid,
       COUNT(*) AS comment_count,
       COALESCE(SUM(c.score), 0) AS total_comment_score
   FROM comments c
   GROUP BY c.userid
),
user_votes_cast AS (
   SELECT
       v.userid AS userid,
       COUNT(*) AS votes_cast,
       COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvote_cast,
       COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvote_cast
   FROM votes v
   GROUP BY v.userid
),
user_votes_received AS (
   SELECT
       p.owneruserid AS userid,
       COUNT(*) AS votes_received,
       COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvote_received,
       COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvote_received
   FROM votes v
   JOIN posts p ON v.postid = p.id
   GROUP BY p.owneruserid
)
SELECT
   u.id AS user_id,
   u.reputation,
   u.creationdate,
   COALESCE(up.post_count, 0) AS post_count,
   COALESCE(up.total_post_score, 0) AS total_post_score,
   COALESCE(up.avg_view_count, 0) AS avg_view_count,
   COALESCE(uc.comment_count, 0) AS comment_count,
   COALESCE(uc.total_comment_score, 0) AS total_comment_score,
   COALESCE(uvc.votes_cast, 0) AS votes_cast,
   COALESCE(uvc.upvote_cast, 0) AS upvote_cast,
   COALESCE(uvc.downvote_cast, 0) AS downvote_cast,
   COALESCE(uvr.votes_received, 0) AS votes_received,
   COALESCE(uvr.upvote_received, 0) AS upvote_received,
   COALESCE(uvr.downvote_received, 0) AS downvote_received
FROM users u
LEFT JOIN user_posts up ON u.id = up.userid
LEFT JOIN user_comments uc ON u.id = uc.userid
LEFT JOIN user_votes_cast uvc ON u.id = uvc.userid
LEFT JOIN user_votes_received uvr ON u.id = uvr.userid
ORDER BY u.reputation DESC
LIMIT 100
