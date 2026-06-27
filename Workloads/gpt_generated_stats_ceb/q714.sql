WITH user_posts AS (
    SELECT
        u.id,
        COUNT(p.id) AS post_count,
        SUM(p.score) AS total_score
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id,
        COUNT(v.id) AS votes_cast
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id,
        COUNT(v.id) AS votes_received
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT
        u.id,
        COUNT(ph.id) AS posthistory_count
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    GROUP BY u.id
)

SELECT
    u.id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_score, 0) AS total_score,
    CASE WHEN COALESCE(up.post_count, 0) = 0 THEN 0
         ELSE up.total_score * 1.0 / up.post_count END AS avg_score,
    COALESCE(uc.votes_cast, 0) AS votes_cast,
    COALESCE(ur.votes_received, 0) AS votes_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uh.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN user_posts up
    ON up.id = u.id
LEFT JOIN user_votes_cast uc
    ON uc.id = u.id
LEFT JOIN user_votes_received ur
    ON ur.id = u.id
LEFT JOIN user_badges ub
    ON ub.id = u.id
LEFT JOIN user_posthistory uh
    ON uh.id = u.id
ORDER BY u.reputation DESC
LIMIT 100
