WITH user_posts AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS post_count,
           SUM(p.score) AS total_post_score,
           AVG(p.score) AS avg_post_score,
           SUM(p.viewcount) AS total_viewcount,
           SUM(p.answercount) AS total_answercount,
           SUM(p.commentcount) AS total_commentcount,
           SUM(p.favoritecount) AS total_favoritecount
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT c.userid AS userid,
           COUNT(*) AS comment_count,
           SUM(c.score) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
),
user_votes_given AS (
    SELECT v.userid AS userid,
           COUNT(*) AS vote_given_count,
           SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_given,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_given
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS vote_received_count,
           SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_received,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT b.userid AS userid,
           COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_posthistory AS (
    SELECT ph.userid AS userid,
           COUNT(*) AS post_history_count
    FROM posthistory ph
    GROUP BY ph.userid
)
SELECT u.id AS user_id,
       u.reputation,
       u.creationdate,
       u.views,
       u.upvotes,
       u.downvotes,
       up.post_count,
       up.total_post_score,
       up.avg_post_score,
       up.total_viewcount,
       up.total_answercount,
       up.total_commentcount,
       up.total_favoritecount,
       uc.comment_count,
       uc.total_comment_score,
       uv.vote_given_count,
       uv.upvote_given,
       uv.downvote_given,
       urv.vote_received_count,
       urv.upvote_received,
       urv.downvote_received,
       ub.badge_count,
       uh.post_history_count
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_given uv ON uv.userid = u.id
LEFT JOIN user_votes_received urv ON urv.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_posthistory uh ON uh.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
