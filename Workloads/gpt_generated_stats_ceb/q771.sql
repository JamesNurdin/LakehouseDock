WITH user_posts AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(score) AS total_post_score,
        AVG(score) AS avg_post_score,
        SUM(viewcount) AS total_viewcount,
        SUM(answercount) AS total_answercount,
        SUM(commentcount) AS total_commentcount,
        SUM(favoritecount) AS total_favoritecount
    FROM posts
    WHERE creationdate >= TIMESTAMP '2023-01-01 00:00:00 UTC'
      AND creationdate < TIMESTAMP '2024-01-01 00:00:00 UTC'
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid,
        COUNT(*) AS comment_count,
        SUM(score) AS total_comment_score,
        AVG(score) AS avg_comment_score
    FROM comments
    WHERE creationdate >= TIMESTAMP '2023-01-01 00:00:00 UTC'
      AND creationdate < TIMESTAMP '2024-01-01 00:00:00 UTC'
    GROUP BY userid
),
user_votes AS (
    SELECT
        userid,
        COUNT(*) AS vote_count,
        SUM(bountyamount) AS total_bounty_amount
    FROM votes
    WHERE creationdate >= TIMESTAMP '2023-01-01 00:00:00 UTC'
      AND creationdate < TIMESTAMP '2024-01-01 00:00:00 UTC'
    GROUP BY userid
),
user_edits AS (
    SELECT
        userid,
        COUNT(*) AS edit_count
    FROM posthistory
    WHERE creationdate >= TIMESTAMP '2023-01-01 00:00:00 UTC'
      AND creationdate < TIMESTAMP '2024-01-01 00:00:00 UTC'
    GROUP BY userid
),
user_last_edits AS (
    SELECT
        lasteditoruserid AS userid,
        COUNT(*) AS last_edit_count
    FROM posts
    WHERE lasteditoruserid IS NOT NULL
      AND creationdate >= TIMESTAMP '2023-01-01 00:00:00 UTC'
      AND creationdate < TIMESTAMP '2024-01-01 00:00:00 UTC'
    GROUP BY lasteditoruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate AS user_creationdate,
    u.views AS user_views,
    u.upvotes AS user_upvotes,
    u.downvotes AS user_downvotes,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(p.total_viewcount, 0) AS total_viewcount,
    COALESCE(p.total_answercount, 0) AS total_answercount,
    COALESCE(p.total_commentcount, 0) AS total_commentcount,
    COALESCE(p.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(c.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(le.last_edit_count, 0) AS last_edit_count
FROM users u
LEFT JOIN user_posts p
    ON p.userid = u.id
LEFT JOIN user_comments c
    ON c.userid = u.id
LEFT JOIN user_votes v
    ON v.userid = u.id
LEFT JOIN user_edits e
    ON e.userid = u.id
LEFT JOIN user_last_edits le
    ON le.userid = u.id
WHERE u.reputation > 0
ORDER BY post_count DESC, comment_count DESC
LIMIT 100
