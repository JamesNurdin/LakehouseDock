WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate,
        COUNT(p.id) AS post_count,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_viewcount,
        SUM(p.answercount) AS total_answercount,
        SUM(p.commentcount) AS total_commentcount,
        SUM(p.favoritecount) AS total_favoritecount
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation, u.creationdate
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count,
        SUM(c.score) AS total_comment_score
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_amount
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS edit_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.reputation,
    up.creationdate,
    up.post_count,
    up.total_post_score,
    up.avg_post_score,
    up.total_viewcount,
    up.total_answercount,
    up.total_commentcount,
    up.total_favoritecount,
    uc.comment_count,
    uc.total_comment_score,
    uv.vote_count,
    uv.upvote_count,
    uv.downvote_count,
    uv.total_bounty_amount,
    ue.edit_count
FROM user_posts up
LEFT JOIN user_comments uc ON uc.user_id = up.user_id
LEFT JOIN user_votes uv ON uv.user_id = up.user_id
LEFT JOIN user_edits ue ON ue.user_id = up.user_id
ORDER BY up.total_post_score DESC
LIMIT 100
