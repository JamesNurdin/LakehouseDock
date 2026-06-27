WITH badge_counts AS (
    SELECT userid, COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
post_counts AS (
    SELECT owneruserid AS userid,
           COUNT(*) AS post_count,
           SUM(score) AS total_post_score,
           SUM(viewcount) AS total_viewcount
    FROM posts
    GROUP BY owneruserid
),
comment_counts AS (
    SELECT userid, COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
votes_cast_counts AS (
    SELECT userid, COUNT(*) AS votes_cast_count
    FROM votes
    GROUP BY userid
),
votes_received_counts AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS votes_received_count
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       u.creationdate,
       COALESCE(bc.badge_count, 0) AS badge_count,
       COALESCE(pc.post_count, 0) AS post_count,
       COALESCE(pc.total_post_score, 0) AS total_post_score,
       COALESCE(pc.total_viewcount, 0) AS total_viewcount,
       COALESCE(cc.comment_count, 0) AS comment_count,
       COALESCE(vc_cast.votes_cast_count, 0) AS votes_cast_count,
       COALESCE(vc_received.votes_received_count, 0) AS votes_received_count,
       (10 * COALESCE(bc.badge_count, 0) +
        5 * COALESCE(pc.post_count, 0) +
        2 * COALESCE(cc.comment_count, 0) +
        1 * COALESCE(vc_cast.votes_cast_count, 0) +
        3 * COALESCE(vc_received.votes_received_count, 0)
       ) AS activity_score
FROM users u
LEFT JOIN badge_counts bc ON bc.userid = u.id
LEFT JOIN post_counts pc ON pc.userid = u.id
LEFT JOIN comment_counts cc ON cc.userid = u.id
LEFT JOIN votes_cast_counts vc_cast ON vc_cast.userid = u.id
LEFT JOIN votes_received_counts vc_received ON vc_received.userid = u.id
ORDER BY activity_score DESC
LIMIT 10
