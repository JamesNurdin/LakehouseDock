WITH user_posts AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS post_cnt,
           COALESCE(SUM(p.score), 0) AS total_score,
           COALESCE(SUM(p.viewcount), 0) AS total_views,
           COALESCE(SUM(p.answercount), 0) AS total_answers,
           COALESCE(SUM(p.commentcount), 0) AS total_comments_on_posts
    FROM posts p
    GROUP BY p.owneruserid
),
user_votes_cast AS (
    SELECT v.userid AS user_id,
           COUNT(*) AS votes_cast_cnt
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT p.owneruserid AS user_id,
           COUNT(v.id) AS votes_received_cnt
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_comments_made AS (
    SELECT c.userid AS user_id,
           COUNT(*) AS comments_made_cnt
    FROM comments c
    GROUP BY c.userid
),
user_comments_received AS (
    SELECT p.owneruserid AS user_id,
           COUNT(c.id) AS comments_received_cnt
    FROM posts p
    LEFT JOIN comments c ON c.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT b.userid AS user_id,
           COUNT(*) AS badge_cnt
    FROM badges b
    GROUP BY b.userid
),
user_links AS (
    SELECT p.owneruserid AS user_id,
           COUNT(pl.id) AS links_cnt
    FROM posts p
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_history_on_posts AS (
    SELECT p.owneruserid AS user_id,
           COUNT(ph.id) AS post_history_cnt
    FROM posts p
    LEFT JOIN posthistory ph ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
),
user_history_actions AS (
    SELECT ph.userid AS user_id,
           COUNT(*) AS history_actions_cnt
    FROM posthistory ph
    GROUP BY ph.userid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.post_cnt, 0) AS post_cnt,
       COALESCE(up.total_score, 0) AS total_post_score,
       COALESCE(up.total_views, 0) AS total_post_views,
       COALESCE(up.total_answers, 0) AS total_post_answers,
       COALESCE(up.total_comments_on_posts, 0) AS total_post_comments,
       COALESCE(uvc.votes_cast_cnt, 0) AS votes_cast,
       COALESCE(uvr.votes_received_cnt, 0) AS votes_received,
       COALESCE(ucm.comments_made_cnt, 0) AS comments_made,
       COALESCE(ucr.comments_received_cnt, 0) AS comments_received,
       COALESCE(ub.badge_cnt, 0) AS badge_cnt,
       COALESCE(ul.links_cnt, 0) AS post_links_cnt,
       COALESCE(uh.post_history_cnt, 0) AS post_history_cnt,
       COALESCE(ua.history_actions_cnt, 0) AS history_actions_cnt
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_comments_made ucm ON ucm.user_id = u.id
LEFT JOIN user_comments_received ucr ON ucr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_links ul ON ul.user_id = u.id
LEFT JOIN user_history_on_posts uh ON uh.user_id = u.id
LEFT JOIN user_history_actions ua ON ua.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 20
