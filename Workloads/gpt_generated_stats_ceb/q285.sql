WITH user_posts AS (
   SELECT
       u.id AS user_id,
       u.reputation,
       COUNT(p.id) AS post_count,
       SUM(p.score) AS total_post_score,
       SUM(p.viewcount) AS total_view_count,
       SUM(p.answercount) AS total_answer_count,
       SUM(p.commentcount) AS total_comment_count,
       SUM(p.favoritecount) AS total_favorite_count
   FROM users u
   LEFT JOIN posts p ON p.owneruserid = u.id
   GROUP BY u.id, u.reputation
),
user_comments AS (
   SELECT
       u.id AS user_id,
       COUNT(c.id) AS comment_count,
       SUM(c.score) AS total_comment_score
   FROM users u
   LEFT JOIN comments c ON c.userid = u.id
   GROUP BY u.id
),
user_votes_cast AS (
   SELECT
       u.id AS user_id,
       COUNT(v.id) AS votes_cast,
       SUM(v.bountyamount) AS total_bounty_given
   FROM users u
   LEFT JOIN votes v ON v.userid = u.id
   GROUP BY u.id
),
user_votes_received AS (
   SELECT
       u.id AS user_id,
       COUNT(v.id) AS votes_received,
       SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
       SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
   FROM users u
   LEFT JOIN posts p ON p.owneruserid = u.id
   LEFT JOIN votes v ON v.postid = p.id
   GROUP BY u.id
),
user_badges AS (
   SELECT
       u.id AS user_id,
       COUNT(b.id) AS badge_count
   FROM users u
   LEFT JOIN badges b ON b.userid = u.id
   GROUP BY u.id
),
user_posthistory AS (
   SELECT
       u.id AS user_id,
       COUNT(ph.id) AS posthistory_count
   FROM users u
   LEFT JOIN posthistory ph ON ph.userid = u.id
   GROUP BY u.id
),
user_tag_excerpts AS (
   SELECT
       u.id AS user_id,
       COUNT(t.id) AS tag_excerpt_count
   FROM users u
   LEFT JOIN posts p ON p.owneruserid = u.id
   LEFT JOIN tags t ON t.excerptpostid = p.id
   GROUP BY u.id
)
SELECT
   u.id AS user_id,
   u.reputation,
   COALESCE(up.post_count, 0) AS post_count,
   COALESCE(up.total_post_score, 0) AS total_post_score,
   COALESCE(up.total_view_count, 0) AS total_view_count,
   COALESCE(uc.comment_count, 0) AS comment_count,
   COALESCE(uc.total_comment_score, 0) AS total_comment_score,
   COALESCE(uvc.votes_cast, 0) AS votes_cast,
   COALESCE(uvr.votes_received, 0) AS votes_received,
   COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
   COALESCE(uvr.downvotes_received, 0) AS downvotes_received,
   COALESCE(ub.badge_count, 0) AS badge_count,
   COALESCE(uph.posthistory_count, 0) AS posthistory_count,
   COALESCE(ute.tag_excerpt_count, 0) AS tag_excerpt_count,
   (COALESCE(up.post_count, 0) * 5
    + COALESCE(uc.comment_count, 0) * 2
    + COALESCE(uvc.votes_cast, 0) * 1
    + COALESCE(ub.badge_count, 0) * 3
    + COALESCE(uph.posthistory_count, 0) * 1
    + COALESCE(ute.tag_excerpt_count, 0) * 2) AS engagement_score
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_tag_excerpts ute ON ute.user_id = u.id
ORDER BY engagement_score DESC
LIMIT 100
