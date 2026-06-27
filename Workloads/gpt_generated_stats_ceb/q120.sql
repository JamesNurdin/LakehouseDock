WITH user_posts AS (
    SELECT u.id AS userid,
           COUNT(p.id) AS post_count,
           COUNT(CASE WHEN p.posttypeid = 1 THEN 1 END) AS question_count,
           COUNT(CASE WHEN p.posttypeid = 2 THEN 1 END) AS answer_count,
           COALESCE(SUM(p.score), 0) AS total_post_score,
           COALESCE(SUM(p.viewcount), 0) AS total_view_count,
           COALESCE(SUM(p.favoritecount), 0) AS total_favorite_count,
           COALESCE(SUM(p.commentcount), 0) AS total_comment_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT u.id AS userid,
           COUNT(v.id) AS votes_received,
           COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_received,
           COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT u.id AS userid,
           COUNT(v.id) AS votes_cast,
           COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_cast,
           COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_cast
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT u.id AS userid,
           COUNT(c.id) AS comment_count,
           COALESCE(SUM(c.score), 0) AS comment_score_sum
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT u.id AS userid,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT u.id AS userid,
           COUNT(ph.id) AS edit_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
),
user_tags AS (
    SELECT u.id AS userid,
           COUNT(DISTINCT t.id) AS tag_expert_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT u.id,
       u.reputation,
       up.post_count,
       up.question_count,
       up.answer_count,
       up.total_post_score,
       up.total_view_count,
       up.total_favorite_count,
       up.total_comment_count,
       ur.votes_received,
       ur.upvote_received,
       ur.downvote_received,
       uc.votes_cast,
       uc.upvote_cast,
       uc.downvote_cast,
       com.comment_count,
       com.comment_score_sum,
       b.badge_count,
       e.edit_count,
       tg.tag_expert_count,
       CASE WHEN up.post_count > 0 THEN up.total_post_score / up.post_count END AS average_post_score
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_votes_received ur ON ur.userid = u.id
LEFT JOIN user_votes_cast uc ON uc.userid = u.id
LEFT JOIN user_comments com ON com.userid = u.id
LEFT JOIN user_badges b ON b.userid = u.id
LEFT JOIN user_edits e ON e.userid = u.id
LEFT JOIN user_tags tg ON tg.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
