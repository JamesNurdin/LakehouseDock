WITH owned_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS owned_post_count,
        COALESCE(SUM(p.score), 0) AS owned_post_score,
        AVG(p.score) AS owned_post_avg_score
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
edited_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS edited_post_count
    FROM users u
    LEFT JOIN posts p
        ON p.lasteditoruserid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS vote_count,
        COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS upvote_count,
        COUNT(CASE WHEN v.votetypeid = 3 THEN 1 END) AS downvote_count
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
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
)
SELECT
    o.user_id,
    o.reputation,
    o.owned_post_count,
    o.owned_post_score,
    o.owned_post_avg_score,
    e.edited_post_count,
    v.vote_count,
    v.upvote_count,
    v.downvote_count,
    b.badge_count,
    (COALESCE(o.owned_post_score, 0) + COALESCE(v.vote_count, 0) + COALESCE(b.badge_count, 0)) AS activity_score
FROM owned_posts o
LEFT JOIN edited_posts e
    ON e.user_id = o.user_id
LEFT JOIN user_votes v
    ON v.user_id = o.user_id
LEFT JOIN user_badges b
    ON b.user_id = o.user_id
ORDER BY activity_score DESC
LIMIT 100
