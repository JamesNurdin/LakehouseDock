WITH user_posts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS post_count,
           COALESCE(SUM(p.score), 0) AS total_score,
           COALESCE(AVG(p.viewcount), 0) AS avg_viewcount
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT u.id AS user_id,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_cast
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
votes_received AS (
    SELECT p.owneruserid AS user_id,
           COUNT(v.id) AS votes_received
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
comments_on_posts AS (
    SELECT p.owneruserid AS user_id,
           COUNT(c.id) AS comment_on_post_count
    FROM posts p
    LEFT JOIN comments c ON c.postid = p.id
    GROUP BY p.owneruserid
),
related_links AS (
    SELECT p.owneruserid AS user_id,
           COUNT(pl.id) AS related_link_count
    FROM posts p
    LEFT JOIN postlinks pl ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
),
posthistory_entries AS (
    SELECT p.owneruserid AS user_id,
           COUNT(ph.id) AS posthistory_count
    FROM posts p
    LEFT JOIN posthistory ph ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.post_count, 0) AS total_posts,
       COALESCE(up.total_score, 0) AS total_post_score,
       COALESCE(up.avg_viewcount, 0) AS avg_post_viewcount,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(uvc.votes_cast, 0) AS votes_cast,
       COALESCE(vr.votes_received, 0) AS votes_received,
       COALESCE(cop.comment_on_post_count, 0) AS comment_on_posts,
       COALESCE(rl.related_link_count, 0) AS related_link_count,
       COALESCE(ph.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN votes_received vr ON vr.user_id = u.id
LEFT JOIN comments_on_posts cop ON cop.user_id = u.id
LEFT JOIN related_links rl ON rl.user_id = u.id
LEFT JOIN posthistory_entries ph ON ph.user_id = u.id
ORDER BY total_posts DESC, user_id
LIMIT 100
