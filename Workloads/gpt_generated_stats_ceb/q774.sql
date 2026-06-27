WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS total_posts,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(SUM(p.answercount), 0) AS total_answers,
        COALESCE(SUM(p.commentcount), 0) AS total_comments_received,
        MIN(p.creationdate) AS first_post_date,
        MAX(p.creationdate) AS last_post_date
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_comments_made AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS total_comments_made
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS total_votes_cast
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS total_votes_received
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS total_badges
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS total_post_edits,
        MAX(ph.creationdate) AS last_edit_date
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.reputation,
    up.total_posts,
    up.total_post_score,
    up.total_answers,
    up.total_comments_received,
    up.first_post_date,
    up.last_post_date,
    cm.total_comments_made,
    vc.total_votes_cast,
    vr.total_votes_received,
    b.total_badges,
    e.total_post_edits,
    e.last_edit_date
FROM user_posts up
LEFT JOIN user_comments_made cm ON cm.user_id = up.user_id
LEFT JOIN user_votes_cast vc ON vc.user_id = up.user_id
LEFT JOIN user_votes_received vr ON vr.user_id = up.user_id
LEFT JOIN user_badges b ON b.user_id = up.user_id
LEFT JOIN user_edits e ON e.user_id = up.user_id
ORDER BY up.reputation DESC
LIMIT 100
