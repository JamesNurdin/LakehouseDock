WITH user_posts AS (
    SELECT owneruserid AS userid,
           count(*) AS post_count,
           sum(score) AS total_post_score,
           sum(viewcount) AS total_viewcount,
           avg(viewcount) AS avg_viewcount,
           sum(answercount) AS total_answer_count,
           sum(commentcount) AS total_comment_count
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT userid,
           count(*) AS comment_count,
           sum(score) AS total_comment_score
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT userid,
           count(*) AS vote_count,
           sum(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
           sum(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT userid,
           count(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT userid,
           count(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(up.avg_viewcount, 0) AS avg_viewcount,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.total_comment_score, 0) AS total_comment_score,
       COALESCE(uv.vote_count, 0) AS vote_count,
       COALESCE(uv.upvote_count, 0) AS upvote_count,
       COALESCE(uv.downvote_count, 0) AS downvote_count,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(uph.posthistory_count, 0) AS posthistory_count,
       CASE WHEN COALESCE(up.post_count, 0) = 0 THEN 0
            ELSE COALESCE(up.total_post_score, 0) * 1.0 / up.post_count END AS avg_post_score,
       CASE WHEN COALESCE(up.post_count, 0) = 0 THEN 0
            ELSE COALESCE(uc.comment_count, 0) * 1.0 / up.post_count END AS comments_per_post
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes uv ON uv.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
