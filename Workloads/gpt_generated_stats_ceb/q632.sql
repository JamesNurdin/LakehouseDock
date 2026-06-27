WITH comment_agg AS (
    SELECT
        postid,
        COUNT(*) AS comment_cnt,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY postid
),
vote_agg AS (
    SELECT
        postid,
        COUNT(*) AS vote_cnt,
        SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cnt,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cnt,
        SUM(COALESCE(bountyamount, 0)) AS total_bounty
    FROM votes
    GROUP BY postid
),
posthistory_agg AS (
    SELECT
        posthistorytypeid AS postid,
        COUNT(*) AS history_cnt
    FROM posthistory
    GROUP BY posthistorytypeid
)
SELECT
    p.id AS post_id,
    p.posttypeid,
    p.creationdate,
    p.score AS post_score,
    p.viewcount,
    p.answercount,
    p.commentcount,
    p.favoritecount,
    o.reputation AS owner_reputation,
    e.reputation AS last_editor_reputation,
    COALESCE(c.comment_cnt, 0) AS comment_cnt,
    COALESCE(c.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(v.vote_cnt, 0) AS vote_cnt,
    COALESCE(v.upvote_cnt, 0) AS upvote_cnt,
    COALESCE(v.downvote_cnt, 0) AS downvote_cnt,
    COALESCE(v.total_bounty, 0) AS total_bounty,
    COALESCE(ph.history_cnt, 0) AS posthistory_cnt
FROM posts p
LEFT JOIN users o ON p.owneruserid = o.id
LEFT JOIN users e ON p.lasteditoruserid = e.id
LEFT JOIN comment_agg c ON c.postid = p.id
LEFT JOIN vote_agg v ON v.postid = p.id
LEFT JOIN posthistory_agg ph ON ph.postid = p.id
ORDER BY p.creationdate DESC
LIMIT 50
