-- User activity summary: total owned posts, edited posts, votes cast and badges earned per user
-- plus average score of owned posts
WITH owned_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS posts_owned,
        AVG(score) AS avg_score_owned
    FROM posts
    GROUP BY owneruserid
),
edited_posts AS (
    SELECT
        lasteditoruserid AS user_id,
        COUNT(*) AS posts_edited
    FROM posts
    GROUP BY lasteditoruserid
),
votes_cast AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS votes_cast
    FROM votes
    GROUP BY userid
),
badges_earned AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badges_earned
    FROM badges
    GROUP BY userid
),
user_base AS (
    SELECT
        id AS user_id,
        reputation
    FROM users
)
SELECT
    ub.user_id,
    ub.reputation,
    COALESCE(op.posts_owned, 0)      AS posts_owned,
    COALESCE(op.avg_score_owned, 0)  AS avg_score_owned,
    COALESCE(ep.posts_edited, 0)     AS posts_edited,
    COALESCE(vc.votes_cast, 0)      AS votes_cast,
    COALESCE(be.badges_earned, 0)    AS badges_earned
FROM user_base ub
LEFT JOIN owned_posts   op ON op.user_id = ub.user_id
LEFT JOIN edited_posts  ep ON ep.user_id = ub.user_id
LEFT JOIN votes_cast    vc ON vc.user_id = ub.user_id
LEFT JOIN badges_earned be ON be.user_id = ub.user_id
ORDER BY posts_owned DESC
LIMIT 100
