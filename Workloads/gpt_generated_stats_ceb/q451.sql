WITH user_posts AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS post_count,
           SUM(p.score) AS total_post_score
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT c.userid,
           COUNT(*) AS comment_count,
           SUM(c.score) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
),
user_votes_cast AS (
    SELECT v.userid,
           COUNT(*) AS votes_cast
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT p.owneruserid AS userid,
           COUNT(v.id) AS votes_received
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT b.userid,
           COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_edits AS (
    SELECT ph.userid,
           COUNT(*) AS edit_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_postlinks AS (
    SELECT p.owneruserid AS userid,
           COUNT(pl.id) AS postlink_count
    FROM posts p
    JOIN postlinks pl ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT p.owneruserid AS userid,
           COUNT(t.id) AS tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(p.post_count, 0) AS post_count,
       COALESCE(p.total_post_score, 0) AS total_post_score,
       COALESCE(c.comment_count, 0) AS comment_count,
       COALESCE(c.total_comment_score, 0) AS total_comment_score,
       COALESCE(vc.votes_cast, 0) AS votes_cast,
       COALESCE(vr.votes_received, 0) AS votes_received,
       COALESCE(b.badge_count, 0) AS badge_count,
       COALESCE(e.edit_count, 0) AS edit_count,
       COALESCE(pl.postlink_count, 0) AS postlink_count,
       COALESCE(tg.tag_count, 0) AS tag_count,
       (COALESCE(p.total_post_score, 0) * 0.5
        + COALESCE(c.total_comment_score, 0) * 0.3
        + COALESCE(vc.votes_cast, 0) * 0.1
        + COALESCE(vr.votes_received, 0) * 0.2
        + COALESCE(b.badge_count, 0) * 5
        + COALESCE(e.edit_count, 0) * 0.05
        + COALESCE(pl.postlink_count, 0) * 0.05
        + COALESCE(tg.tag_count, 0) * 0.02) AS activity_score
FROM users u
LEFT JOIN user_posts p ON p.userid = u.id
LEFT JOIN user_comments c ON c.userid = u.id
LEFT JOIN user_votes_cast vc ON vc.userid = u.id
LEFT JOIN user_votes_received vr ON vr.userid = u.id
LEFT JOIN user_badges b ON b.userid = u.id
LEFT JOIN user_edits e ON e.userid = u.id
LEFT JOIN user_postlinks pl ON pl.userid = u.id
LEFT JOIN user_tags tg ON tg.userid = u.id
ORDER BY activity_score DESC
LIMIT 10
