WITH user_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS post_owned_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_post_views
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS vote_cast_count
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS posthistory_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
),
user_tags AS (
    SELECT
        u.id AS user_id,
        COUNT(t.id) AS tag_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
),
users_base AS (
    SELECT
        id AS user_id,
        reputation
    FROM users
)
SELECT
    ub.user_id,
    ub.reputation,
    up.post_owned_count,
    up.total_post_score,
    up.total_post_views,
    uc.comment_count,
    uv.vote_cast_count,
    ubg.badge_count,
    uph.posthistory_count,
    ut.tag_count,
    CASE WHEN up.post_owned_count > 0 THEN up.total_post_score / up.post_owned_count ELSE NULL END AS avg_post_score,
    RANK() OVER (ORDER BY ub.reputation DESC) AS reputation_rank
FROM users_base ub
LEFT JOIN user_posts up ON up.user_id = ub.user_id
LEFT JOIN user_comments uc ON uc.user_id = ub.user_id
LEFT JOIN user_votes uv ON uv.user_id = ub.user_id
LEFT JOIN user_badges ubg ON ubg.user_id = ub.user_id
LEFT JOIN user_posthistory uph ON uph.user_id = ub.user_id
LEFT JOIN user_tags ut ON ut.user_id = ub.user_id
ORDER BY ub.reputation DESC
LIMIT 100
