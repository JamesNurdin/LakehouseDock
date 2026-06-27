WITH user_posts AS (
    SELECT
        users.id AS user_id,
        COUNT(*) AS total_posts,
        AVG(posts.score) AS avg_post_score,
        COUNT(*) FILTER (WHERE posts.posttypeid = 1) AS total_questions,
        COUNT(*) FILTER (WHERE posts.posttypeid = 2) AS total_answers
    FROM users
    JOIN posts ON posts.owneruserid = users.id
    GROUP BY users.id
),
user_comments AS (
    SELECT
        users.id AS user_id,
        COUNT(*) AS total_comments
    FROM users
    JOIN comments ON comments.userid = users.id
    GROUP BY users.id
),
user_votes_cast AS (
    SELECT
        users.id AS user_id,
        COUNT(*) AS total_votes_cast
    FROM users
    JOIN votes ON votes.userid = users.id
    GROUP BY users.id
),
user_votes_received AS (
    SELECT
        users.id AS user_id,
        COUNT(*) AS total_votes_received
    FROM users
    JOIN posts ON posts.owneruserid = users.id
    JOIN votes ON votes.postid = posts.id
    GROUP BY users.id
),
user_badges AS (
    SELECT
        users.id AS user_id,
        COUNT(*) AS total_badges
    FROM users
    JOIN badges ON badges.userid = users.id
    GROUP BY users.id
)
SELECT
    users.id,
    users.reputation,
    date_diff('day', users.creationdate, current_timestamp) AS account_age_days,
    COALESCE(user_posts.total_posts, 0) AS total_posts,
    COALESCE(user_posts.avg_post_score, 0) AS avg_post_score,
    COALESCE(user_posts.total_questions, 0) AS total_questions,
    COALESCE(user_posts.total_answers, 0) AS total_answers,
    COALESCE(user_comments.total_comments, 0) AS total_comments,
    COALESCE(user_votes_cast.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(user_votes_received.total_votes_received, 0) AS total_votes_received,
    COALESCE(user_badges.total_badges, 0) AS total_badges
FROM users
LEFT JOIN user_posts ON user_posts.user_id = users.id
LEFT JOIN user_comments ON user_comments.user_id = users.id
LEFT JOIN user_votes_cast ON user_votes_cast.user_id = users.id
LEFT JOIN user_votes_received ON user_votes_received.user_id = users.id
LEFT JOIN user_badges ON user_badges.user_id = users.id
ORDER BY users.reputation DESC
LIMIT 10
