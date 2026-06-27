WITH user_posts AS (
    SELECT
        u.id AS id,
        u.reputation,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(AVG(p.score), 0) AS avg_post_score
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_votes_cast AS (
    SELECT
        u.id AS id,
        COUNT(v.id) AS votes_cast,
        COALESCE(SUM(CASE WHEN v.bountyamount IS NOT NULL THEN v.bountyamount ELSE 0 END), 0) AS bounty_amount_cast
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS id,
        COUNT(v.id) AS votes_received,
        COALESCE(SUM(CASE WHEN v.bountyamount IS NOT NULL THEN v.bountyamount ELSE 0 END), 0) AS bounty_amount_received
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT
        u.id AS id,
        COUNT(ph.id) AS posthistory_events
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    GROUP BY u.id
)
SELECT
    up.id AS user_id,
    up.reputation,
    up.post_count,
    up.total_post_score,
    up.avg_post_score,
    uv_cast.votes_cast,
    uv_cast.bounty_amount_cast,
    uv_received.votes_received,
    uv_received.bounty_amount_received,
    uph.posthistory_events
FROM user_posts up
LEFT JOIN user_votes_cast uv_cast
    ON uv_cast.id = up.id
LEFT JOIN user_votes_received uv_received
    ON uv_received.id = up.id
LEFT JOIN user_posthistory uph
    ON uph.id = up.id
ORDER BY up.total_post_score DESC
LIMIT 100
