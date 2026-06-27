WITH daily_vote_metrics AS (
    SELECT
        date_trunc('day', v.creationdate) AS vote_day,
        COUNT(*) AS total_votes,
        SUM(v.bountyamount) AS total_bounty,
        COUNT(DISTINCT v.userid) AS distinct_voters,
        AVG(u.reputation) AS avg_user_reputation,
        AVG(u.upvotes) AS avg_user_upvotes,
        AVG(u.downvotes) AS avg_user_downvotes
    FROM votes v
    JOIN users u
      ON v.userid = u.id
    GROUP BY date_trunc('day', v.creationdate)
    HAVING COUNT(*) > 100
)
SELECT
    vote_day,
    total_votes,
    total_bounty,
    distinct_voters,
    avg_user_reputation,
    avg_user_upvotes,
    avg_user_downvotes
FROM daily_vote_metrics
ORDER BY vote_day DESC
