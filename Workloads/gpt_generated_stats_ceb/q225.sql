WITH user_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS posts_owned,
        SUM(score) AS total_post_score,
        AVG(score) AS avg_post_score
    FROM posts
    GROUP BY owneruserid
),
user_edits AS (
    SELECT
        lasteditoruserid AS user_id,
        COUNT(*) AS posts_edited
    FROM posts
    WHERE lasteditoruserid IS NOT NULL
    GROUP BY lasteditoruserid
),
user_comments AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comments_made,
        SUM(score) AS total_comment_score,
        AVG(score) AS avg_comment_score
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS votes_cast,
        SUM(COALESCE(bountyamount, 0)) AS total_bounty_given
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badges_earned
    FROM badges
    GROUP BY userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate AS user_creationdate,
    COALESCE(up.posts_owned, 0) AS posts_owned,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(ue.posts_edited, 0) AS posts_edited,
    COALESCE(uc.comments_made, 0) AS comments_made,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(uv.votes_cast, 0) AS votes_cast,
    COALESCE(uv.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(ub.badges_earned, 0) AS badges_earned,
    RANK() OVER (ORDER BY u.reputation DESC) AS reputation_rank
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes uv ON uv.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
