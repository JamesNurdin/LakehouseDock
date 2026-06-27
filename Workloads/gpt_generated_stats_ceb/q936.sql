WITH user_posts AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS post_count,
           COALESCE(SUM(p.score), 0) AS total_post_score,
           COALESCE(SUM(p.viewcount), 0) AS total_view_count,
           COALESCE(SUM(p.answercount), 0) AS total_answer_count,
           MIN(p.creationdate) AS first_post_date
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT c.userid AS user_id,
           COUNT(*) AS comment_count,
           COALESCE(SUM(c.score), 0) AS total_comment_score,
           MIN(c.creationdate) AS first_comment_date
    FROM comments c
    GROUP BY c.userid
),
user_badges AS (
    SELECT b.userid AS user_id,
           COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_posthistory AS (
    SELECT ph.userid AS user_id,
           COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_votes_cast AS (
    SELECT v.userid AS user_id,
           COUNT(*) AS votes_cast_count,
           COALESCE(SUM(v.bountyamount), 0) AS bounty_amount_cast
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS votes_received_count,
           COALESCE(SUM(v.bountyamount), 0) AS bounty_amount_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_tag_usage AS (
    SELECT p.owneruserid AS user_id,
           COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_postlinks AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS postlinks_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(up.total_view_count, 0) AS total_view_count,
       COALESCE(up.total_answer_count, 0) AS total_answer_count,
       up.first_post_date,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.total_comment_score, 0) AS total_comment_score,
       uc.first_comment_date,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(uph.posthistory_count, 0) AS posthistory_count,
       COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
       COALESCE(uvc.bounty_amount_cast, 0) AS bounty_amount_cast,
       COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
       COALESCE(uvr.bounty_amount_received, 0) AS bounty_amount_received,
       COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count,
       COALESCE(ul.postlinks_count, 0) AS postlinks_count
FROM users u
LEFT JOIN user_posts up           ON up.user_id = u.id
LEFT JOIN user_comments uc       ON uc.user_id = u.id
LEFT JOIN user_badges ub         ON ub.user_id = u.id
LEFT JOIN user_posthistory uph   ON uph.user_id = u.id
LEFT JOIN user_votes_cast uvc    ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_tag_usage ut      ON ut.user_id = u.id
LEFT JOIN user_postlinks ul      ON ul.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 20
