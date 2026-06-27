WITH post_month AS (
    SELECT
        id,
        date_trunc('month', creationdate) AS month,
        score,
        viewcount,
        owneruserid,
        answercount,
        commentcount,
        favoritecount
    FROM posts
),
comments_agg AS (
    SELECT
        postid,
        COUNT(*) AS comment_cnt,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY postid
),
votes_agg AS (
    SELECT
        postid,
        COUNT(*) AS vote_cnt,
        SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cnt,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cnt,
        SUM(bountyamount) AS total_bounty
    FROM votes
    GROUP BY postid
)
SELECT
    pm.month,
    COUNT(DISTINCT pm.id) AS posts_created,
    SUM(pm.score) AS total_post_score,
    AVG(pm.score) AS avg_post_score,
    SUM(pm.viewcount) AS total_views,
    AVG(pm.viewcount) AS avg_views,
    SUM(pm.answercount) AS total_answers,
    AVG(pm.answercount) AS avg_answers,
    SUM(COALESCE(ca.comment_cnt, 0)) AS total_comments,
    SUM(COALESCE(ca.comment_score_sum, 0)) AS total_comment_score,
    SUM(COALESCE(va.vote_cnt, 0)) AS total_votes,
    SUM(COALESCE(va.upvote_cnt, 0)) AS total_upvotes,
    SUM(COALESCE(va.downvote_cnt, 0)) AS total_downvotes,
    SUM(COALESCE(va.total_bounty, 0)) AS total_bounty_amount,
    COUNT(DISTINCT pm.owneruserid) AS distinct_owners,
    AVG(u.reputation) AS avg_owner_reputation
FROM post_month pm
LEFT JOIN comments_agg ca ON pm.id = ca.postid
LEFT JOIN votes_agg va ON pm.id = va.postid
LEFT JOIN users u ON pm.owneruserid = u.id
GROUP BY pm.month
ORDER BY pm.month
