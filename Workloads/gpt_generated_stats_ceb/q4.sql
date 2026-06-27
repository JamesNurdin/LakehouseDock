WITH vote_counts AS (
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
    p.posttypeid,
    COUNT(DISTINCT p.id) AS total_posts,
    SUM(p.score) AS total_score,
    AVG(p.score) AS avg_score,
    SUM(COALESCE(vc.vote_cnt, 0)) AS total_votes,
    AVG(COALESCE(vc.vote_cnt, 0)) AS avg_votes_per_post,
    SUM(COALESCE(vc.upvote_cnt, 0)) AS total_upvotes,
    SUM(COALESCE(vc.downvote_cnt, 0)) AS total_downvotes,
    SUM(COALESCE(vc.total_bounty, 0)) AS total_bounty_amount
FROM posts AS p
LEFT JOIN vote_counts AS vc
    ON vc.postid = p.id
GROUP BY p.posttypeid
ORDER BY p.posttypeid
