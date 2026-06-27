WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS post_count,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_views,
        SUM(p.favoritecount) AS total_favorites
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count,
        SUM(c.score) AS total_comment_score,
        AVG(c.score) AS avg_comment_score
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS vote_cast_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cast,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cast
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.reputation,
    up.post_count,
    up.total_post_score,
    up.avg_post_score,
    up.total_views,
    up.total_favorites,
    uc.comment_count,
    uc.total_comment_score,
    uc.avg_comment_score,
    uv.vote_cast_count,
    uv.upvote_cast,
    uv.downvote_cast
FROM user_posts up
LEFT JOIN user_comments uc
    ON uc.user_id = up.user_id
LEFT JOIN user_votes uv
    ON uv.user_id = up.user_id
ORDER BY up.post_count DESC
LIMIT 100
