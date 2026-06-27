WITH user_posts AS (
    SELECT p.owneruserid AS user_id,
           count(*) AS post_cnt,
           sum(p.score) AS total_score,
           avg(p.score) AS avg_score,
           sum(p.viewcount) AS total_views,
           sum(p.answercount) AS total_answers,
           sum(p.commentcount) AS total_comments_received
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT c.userid AS user_id,
           count(*) AS comment_cnt
    FROM comments c
    GROUP BY c.userid
),
user_votes_cast AS (
    SELECT v.userid AS user_id,
           count(*) AS votes_cast_cnt
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT p.owneruserid AS user_id,
           count(*) AS votes_received_cnt
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT b.userid AS user_id,
           count(*) AS badge_cnt
    FROM badges b
    GROUP BY b.userid
),
user_edits AS (
    SELECT p.lasteditoruserid AS user_id,
           count(*) AS edit_cnt
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
),
user_posthistory AS (
    SELECT ph.userid AS user_id,
           count(*) AS history_cnt
    FROM posthistory ph
    GROUP BY ph.userid
)
SELECT u.id AS user_id,
       u.reputation,
       coalesce(p.post_cnt, 0) AS total_posts,
       coalesce(p.total_score, 0) AS total_post_score,
       coalesce(p.avg_score, 0) AS avg_post_score,
       coalesce(p.total_views, 0) AS total_post_views,
       coalesce(p.total_answers, 0) AS total_answers,
       coalesce(p.total_comments_received, 0) AS comments_received_on_posts,
       coalesce(c.comment_cnt, 0) AS comments_made,
       coalesce(vc.votes_cast_cnt, 0) AS votes_cast,
       coalesce(vr.votes_received_cnt, 0) AS votes_received,
       coalesce(b.badge_cnt, 0) AS badges_earned,
       coalesce(e.edit_cnt, 0) AS posts_edited,
       coalesce(ph.history_cnt, 0) AS post_history_events
FROM users u
LEFT JOIN user_posts p ON u.id = p.user_id
LEFT JOIN user_comments c ON u.id = c.user_id
LEFT JOIN user_votes_cast vc ON u.id = vc.user_id
LEFT JOIN user_votes_received vr ON u.id = vr.user_id
LEFT JOIN user_badges b ON u.id = b.user_id
LEFT JOIN user_edits e ON u.id = e.user_id
LEFT JOIN user_posthistory ph ON u.id = ph.user_id
ORDER BY u.reputation DESC
LIMIT 10
