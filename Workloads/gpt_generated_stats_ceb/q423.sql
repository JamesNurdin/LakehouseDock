WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.views,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(AVG(p.score), 0) AS avg_post_score
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation, u.views
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast,
        COUNT_IF(v.votetypeid = 2) AS upvotes_cast,
        COUNT_IF(v.votetypeid = 3) AS downvotes_cast
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_received,
        COUNT_IF(v.votetypeid = 2) AS upvotes_received,
        COUNT_IF(v.votetypeid = 3) AS downvotes_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.reputation,
    up.views,
    up.post_count,
    up.total_post_score,
    up.avg_post_score,
    uvc.votes_cast,
    uvc.upvotes_cast,
    uvc.downvotes_cast,
    uvr.votes_received,
    uvr.upvotes_received,
    uvr.downvotes_received
FROM user_posts up
LEFT JOIN user_votes_cast uvc ON uvc.user_id = up.user_id
LEFT JOIN user_votes_received uvr ON uvr.user_id = up.user_id
ORDER BY up.total_post_score DESC
LIMIT 20
