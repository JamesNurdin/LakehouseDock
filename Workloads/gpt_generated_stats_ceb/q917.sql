WITH user_posts AS (
    SELECT
        users.id AS user_id,
        COUNT(posts.id) AS post_count,
        SUM(posts.score) AS total_post_score,
        AVG(posts.score) AS avg_post_score
    FROM users
    LEFT JOIN posts ON posts.owneruserid = users.id
    GROUP BY users.id
),
user_comments AS (
    SELECT
        users.id AS user_id,
        COUNT(comments.id) AS comment_count,
        SUM(comments.score) AS total_comment_score
    FROM users
    LEFT JOIN comments ON comments.userid = users.id
    GROUP BY users.id
),
user_votes_cast AS (
    SELECT
        users.id AS user_id,
        COUNT(votes.id) AS votes_cast,
        SUM(CASE WHEN votes.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_cast,
        SUM(CASE WHEN votes.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM users
    LEFT JOIN votes ON votes.userid = users.id
    GROUP BY users.id
),
user_votes_received AS (
    SELECT
        users.id AS user_id,
        COUNT(votes.id) AS votes_received,
        SUM(CASE WHEN votes.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN votes.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
    FROM users
    LEFT JOIN posts ON posts.owneruserid = users.id
    LEFT JOIN votes ON votes.postid = posts.id
    GROUP BY users.id
),
user_badges AS (
    SELECT
        users.id AS user_id,
        COUNT(badges.id) AS badge_count
    FROM users
    LEFT JOIN badges ON badges.userid = users.id
    GROUP BY users.id
)
SELECT
    u.id,
    u.reputation,
    up.post_count,
    up.total_post_score,
    up.avg_post_score,
    uc.comment_count,
    uc.total_comment_score,
    uv_cast.votes_cast,
    uv_cast.upvotes_cast,
    uv_cast.downvotes_cast,
    uv_received.votes_received,
    uv_received.upvotes_received,
    uv_received.downvotes_received,
    ub.badge_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uv_cast ON uv_cast.user_id = u.id
LEFT JOIN user_votes_received uv_received ON uv_received.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
WHERE u.reputation > 1000
ORDER BY u.reputation DESC
LIMIT 20
