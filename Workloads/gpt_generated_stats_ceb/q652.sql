WITH vote_user AS (
    SELECT
        v.id AS vote_id,
        v.votetypeid,
        v.bountyamount,
        v.creationdate AS vote_creationdate,
        v.userid,
        u.id AS user_id,
        u.reputation,
        u.creationdate AS user_creationdate,
        u.views,
        u.upvotes,
        u.downvotes
    FROM votes v
    JOIN users u
        ON v.userid = u.id
)
SELECT
    DATE_TRUNC('month', vote_creationdate) AS vote_month,
    votetypeid,
    COUNT(*) AS votes_count,
    SUM(COALESCE(bountyamount, 0)) AS total_bounty,
    AVG(COALESCE(bountyamount, 0)) AS avg_bounty,
    AVG(reputation) AS avg_user_reputation,
    SUM(views) AS total_user_views,
    AVG(upvotes) AS avg_user_upvotes,
    AVG(downvotes) AS avg_user_downvotes
FROM vote_user
GROUP BY DATE_TRUNC('month', vote_creationdate), votetypeid
ORDER BY vote_month DESC, votes_count DESC
