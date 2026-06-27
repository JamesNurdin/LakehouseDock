WITH post_metrics AS (
    SELECT
        p.id AS post_id,
        p.owneruserid AS owner_user_id,
        p.creationdate AS post_creationdate,
        p.score AS post_score,
        p.viewcount AS post_viewcount,
        p.answercount AS post_answercount,
        p.commentcount AS post_commentcount,
        p.favoritecount AS post_favoritecount,
        u.reputation AS owner_reputation,
        COUNT(DISTINCT c.id) AS comment_count,
        COALESCE(SUM(c.score), 0) AS comment_score_sum,
        COALESCE(AVG(c.score), 0) AS comment_score_avg,
        COUNT(DISTINCT v.id) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty_amount
    FROM posts p
    JOIN users u ON p.owneruserid = u.id
    LEFT JOIN comments c ON c.postid = p.id
    LEFT JOIN votes v ON v.postid = p.id
    WHERE p.posttypeid = 1
    GROUP BY
        p.id,
        p.owneruserid,
        p.creationdate,
        p.score,
        p.viewcount,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        u.reputation
)
SELECT
    post_id,
    owner_user_id,
    post_creationdate,
    post_score,
    post_viewcount,
    post_answercount,
    post_commentcount,
    post_favoritecount,
    owner_reputation,
    comment_count,
    comment_score_sum,
    comment_score_avg,
    vote_count,
    upvote_count,
    downvote_count,
    total_bounty_amount
FROM post_metrics
ORDER BY post_score DESC
LIMIT 100
