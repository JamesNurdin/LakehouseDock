WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS total_posts,
        SUM(CASE WHEN p.posttypeid = 1 THEN 1 ELSE 0 END) AS question_count,
        SUM(CASE WHEN p.posttypeid = 2 THEN 1 ELSE 0 END) AS answer_count,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_views
    FROM users u
    JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS total_comments,
        AVG(c.score) AS avg_comment_score,
        SUM(c.score) AS sum_comment_score
    FROM users u
    JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS total_votes,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(v.bountyamount) AS total_bounty_awarded
    FROM users u
    JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_tags AS (
    SELECT
        u.id AS user_id,
        COUNT(DISTINCT t.id) AS distinct_tags_used
    FROM users u
    JOIN posts p ON p.owneruserid = u.id
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT
    ROW_NUMBER() OVER (ORDER BY up.total_posts DESC) AS user_rank,
    up.user_id,
    up.reputation,
    up.total_posts,
    up.question_count,
    up.answer_count,
    up.avg_post_score,
    up.total_views,
    uc.total_comments,
    uc.avg_comment_score,
    uv.total_votes,
    uv.upvote_count,
    uv.downvote_count,
    uv.total_bounty_awarded,
    ut.distinct_tags_used
FROM user_posts up
LEFT JOIN user_comments uc ON uc.user_id = up.user_id
LEFT JOIN user_votes uv ON uv.user_id = up.user_id
LEFT JOIN user_tags ut ON ut.user_id = up.user_id
ORDER BY up.total_posts DESC
LIMIT 10
