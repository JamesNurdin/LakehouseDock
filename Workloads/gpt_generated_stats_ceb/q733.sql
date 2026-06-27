/*
  Analytical query: summary of user activity across posts, comments, votes, badges, edits, and post links.
  The query aggregates per‑user metrics and returns the top 10 users by reputation.
*/
WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(AVG(p.score), 0) AS avg_post_score
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
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
        u.id AS user_id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS edit_count
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    GROUP BY u.id
),
user_links AS (
    SELECT
        u.id AS user_id,
        COUNT(pl.id) AS link_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
        ON pl.postid = p.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.reputation,
    up.post_count,
    up.total_post_score,
    up.avg_post_score,
    uc.comment_count,
    uv_cast.votes_cast,
    uv_received.votes_received,
    ub.badge_count,
    ue.edit_count,
    ul.link_count
FROM user_posts up
LEFT JOIN user_comments uc
    ON uc.user_id = up.user_id
LEFT JOIN user_votes_cast uv_cast
    ON uv_cast.user_id = up.user_id
LEFT JOIN user_votes_received uv_received
    ON uv_received.user_id = up.user_id
LEFT JOIN user_badges ub
    ON ub.user_id = up.user_id
LEFT JOIN user_edits ue
    ON ue.user_id = up.user_id
LEFT JOIN user_links ul
    ON ul.user_id = up.user_id
ORDER BY up.reputation DESC
LIMIT 10
