SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(tg.tag_excerpt_count, 0) AS tag_excerpt_count
FROM users u
LEFT JOIN (
    SELECT userid, COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
) b
    ON b.userid = u.id
LEFT JOIN (
    SELECT owneruserid, COUNT(*) AS post_count, AVG(score) AS avg_post_score
    FROM posts
    GROUP BY owneruserid
) p
    ON p.owneruserid = u.id
LEFT JOIN (
    SELECT userid, COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
) c
    ON c.userid = u.id
LEFT JOIN (
    SELECT userid, COUNT(*) AS votes_cast
    FROM votes
    GROUP BY userid
) vc
    ON vc.userid = u.id
LEFT JOIN (
    SELECT p.owneruserid AS userid, COUNT(*) AS votes_received
    FROM votes v
    JOIN posts p
        ON v.postid = p.id
    GROUP BY p.owneruserid
) vr
    ON vr.userid = u.id
LEFT JOIN (
    SELECT p.owneruserid AS userid, COUNT(DISTINCT t.id) AS tag_excerpt_count
    FROM tags t
    JOIN posts p
        ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
) tg
    ON tg.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
