WITH owned_posts AS (
    SELECT u.id AS user_id,
           COUNT(DISTINCT p.id) AS posts_owned,
           SUM(p.score) AS total_post_score,
           AVG(p.score) AS avg_post_score,
           SUM(p.viewcount) AS total_viewcount
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
edited_posts AS (
    SELECT u.id AS user_id,
           COUNT(DISTINCT p.id) AS posts_edited
    FROM users u
    LEFT JOIN posts p ON p.lasteditoruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT u.id AS user_id,
           COUNT(DISTINCT c.id) AS comments_made
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
votes_cast AS (
    SELECT u.id AS user_id,
           COUNT(DISTINCT v.id) AS votes_cast
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
votes_received AS (
    SELECT u.id AS user_id,
           COUNT(DISTINCT v.id) AS votes_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_badges AS (
    SELECT u.id AS user_id,
           COUNT(DISTINCT b.id) AS badges_earned
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT u.id AS user_id,
           COUNT(DISTINCT ph.id) AS posthistory_events
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
),
user_tag_excerpts AS (
    SELECT u.id AS user_id,
           COUNT(DISTINCT t.id) AS tag_excerpts
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT u.id,
       u.reputation,
       COALESCE(op.posts_owned, 0) AS posts_owned,
       COALESCE(ep.posts_edited, 0) AS posts_edited,
       COALESCE(op.total_post_score, 0) AS total_post_score,
       COALESCE(op.avg_post_score, 0) AS avg_post_score,
       COALESCE(op.total_viewcount, 0) AS total_viewcount,
       COALESCE(uc.comments_made, 0) AS comments_made,
       COALESCE(vc.votes_cast, 0) AS votes_cast,
       COALESCE(vr.votes_received, 0) AS votes_received,
       COALESCE(ub.badges_earned, 0) AS badges_earned,
       COALESCE(uph.posthistory_events, 0) AS posthistory_events,
       COALESCE(ute.tag_excerpts, 0) AS tag_excerpts
FROM users u
LEFT JOIN owned_posts op ON op.user_id = u.id
LEFT JOIN edited_posts ep ON ep.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN votes_cast vc ON vc.user_id = u.id
LEFT JOIN votes_received vr ON vr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_tag_excerpts ute ON ute.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
