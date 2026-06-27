WITH user_badges AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posts AS (
    SELECT owneruserid AS userid,
           COUNT(*) AS post_count,
           SUM(score) AS total_post_score,
           SUM(answercount) AS total_answer_count,
           SUM(viewcount) AS total_view_count
    FROM posts
    GROUP BY owneruserid
),
user_votes_cast AS (
    SELECT userid,
           COUNT(*) AS votes_cast_count
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS votes_received_count
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT userid,
           COUNT(*) AS comment_count,
           AVG(score) AS avg_comment_score
    FROM comments
    GROUP BY userid
),
user_posthistory AS (
    SELECT userid,
           COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
user_last_edits AS (
    SELECT u.id AS userid,
           COUNT(*) AS last_edit_count
    FROM posts p
    JOIN users u ON p.lasteditoruserid = u.id
    GROUP BY u.id
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(up.total_answer_count, 0) AS total_answer_count,
       COALESCE(up.total_view_count, 0) AS total_view_count,
       COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
       COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
       COALESCE(uph.posthistory_count, 0) AS posthistory_count,
       COALESCE(ule.last_edit_count, 0) AS last_edit_count,
       CASE WHEN COALESCE(up.post_count, 0) > 0
            THEN COALESCE(up.total_post_score, 0) / COALESCE(up.post_count, 1)
            ELSE 0
       END AS avg_post_score
FROM users u
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
LEFT JOIN user_last_edits ule ON ule.userid = u.id
WHERE u.reputation >= 1000
ORDER BY u.reputation DESC
LIMIT 100
