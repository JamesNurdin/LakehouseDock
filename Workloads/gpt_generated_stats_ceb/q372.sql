WITH post_votes AS (
    SELECT
        postid,
        COUNT(*) AS total_votes,
        SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS up_votes,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS down_votes,
        SUM(CASE WHEN votetypeid = 1 THEN 1 WHEN votetypeid = 2 THEN -1 ELSE 0 END) AS net_vote_score,
        SUM(COALESCE(bountyamount, 0)) AS total_bounty_amount
    FROM votes
    GROUP BY postid
),
post_comments AS (
    SELECT
        postid,
        COUNT(*) AS comment_count,
        AVG(score) AS avg_comment_score,
        MAX(creationdate) AS last_comment_date
    FROM comments
    GROUP BY postid
)
SELECT
    p.id AS post_id,
    p.posttypeid,
    p.creationdate AS post_creationdate,
    p.score AS post_score,
    p.viewcount,
    p.answercount,
    p.commentcount AS post_commentcount_field,
    p.favoritecount,
    COALESCE(pv.total_votes, 0) AS total_votes,
    COALESCE(pv.up_votes, 0) AS up_votes,
    COALESCE(pv.down_votes, 0) AS down_votes,
    COALESCE(pv.net_vote_score, 0) + p.score AS net_score_with_votes,
    COALESCE(pv.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(pc.comment_count, 0) AS comment_count,
    pc.avg_comment_score,
    pc.last_comment_date,
    ou.reputation AS owner_reputation,
    eu.reputation AS editor_reputation,
    (COALESCE(pc.comment_count, 0) * 1.0) / NULLIF(p.viewcount, 0) AS comment_to_view_ratio
FROM posts p
LEFT JOIN post_votes pv ON pv.postid = p.id
LEFT JOIN post_comments pc ON pc.postid = p.id
LEFT JOIN users ou ON p.owneruserid = ou.id
LEFT JOIN users eu ON p.lasteditoruserid = eu.id
WHERE p.posttypeid = 1
  AND p.viewcount > 0
ORDER BY net_score_with_votes DESC
LIMIT 10
