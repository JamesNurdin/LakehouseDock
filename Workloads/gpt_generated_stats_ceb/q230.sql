WITH post_votes AS (
    SELECT
        postid,
        COUNT(*) AS vote_count
    FROM votes
    GROUP BY postid
),
post_comments AS (
    SELECT
        postid,
        COUNT(*) AS comment_count
    FROM comments
    GROUP BY postid
),
user_badges AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_tags AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(DISTINCT t.id) AS tag_count
    FROM posts p
    JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_posthistory AS (
    SELECT
        userid,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COUNT(p.id) AS post_count,
    COALESCE(SUM(p.score), 0) AS total_post_score,
    COALESCE(SUM(pv.vote_count), 0) AS total_vote_count,
    COALESCE(SUM(pc.comment_count), 0) AS total_comment_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ut.tag_count, 0) AS tag_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN posts p
    ON p.owneruserid = u.id
LEFT JOIN post_votes pv
    ON pv.postid = p.id
LEFT JOIN post_comments pc
    ON pc.postid = p.id
LEFT JOIN user_badges ub
    ON ub.userid = u.id
LEFT JOIN user_tags ut
    ON ut.userid = u.id
LEFT JOIN user_posthistory uph
    ON uph.userid = u.id
GROUP BY u.id, u.reputation, ub.badge_count, ut.tag_count, uph.posthistory_count
ORDER BY total_post_score DESC
LIMIT 10
