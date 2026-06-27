WITH user_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS post_count,
        SUM(COALESCE(p.viewcount, 0)) AS total_views,
        SUM(COALESCE(p.score, 0)) AS total_post_score,
        SUM(COALESCE(p.favoritecount, 0)) AS total_favorites
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count,
        SUM(COALESCE(c.score, 0)) AS total_comment_score
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS vote_received_count,
        SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
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
user_tags AS (
    SELECT
        u.id AS user_id,
        COUNT(DISTINCT t.id) AS tag_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_activity AS (
    SELECT
        up.user_id,
        u.reputation,
        up.post_count,
        up.total_views,
        up.total_post_score,
        up.total_favorites,
        uc.comment_count,
        uc.total_comment_score,
        uv.vote_received_count,
        uv.total_bounty_received,
        ub.badge_count,
        ut.tag_count
    FROM user_posts up
    LEFT JOIN users u ON u.id = up.user_id
    LEFT JOIN user_comments uc ON uc.user_id = up.user_id
    LEFT JOIN user_votes_received uv ON uv.user_id = up.user_id
    LEFT JOIN user_badges ub ON ub.user_id = up.user_id
    LEFT JOIN user_tags ut ON ut.user_id = up.user_id
)
SELECT
    user_id,
    reputation,
    post_count,
    comment_count,
    vote_received_count,
    badge_count,
    tag_count,
    total_views,
    total_post_score,
    total_favorites,
    total_comment_score,
    total_bounty_received,
    (CASE WHEN comment_count = 0 THEN NULL ELSE CAST(post_count AS double) / comment_count END) AS posts_per_comment_ratio,
    (CASE WHEN post_count = 0 THEN NULL ELSE CAST(total_views AS double) / post_count END) AS avg_views_per_post
FROM user_activity
ORDER BY reputation DESC
LIMIT 50
