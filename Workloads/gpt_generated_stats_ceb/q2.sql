WITH vote_user AS (
    SELECT
        v.id AS vote_id,
        v.postid,
        v.votetypeid,
        CAST(v.creationdate AS DATE) AS vote_date,
        v.userid,
        v.bountyamount,
        u.reputation,
        u.creationdate AS user_creationdate,
        u.views,
        u.upvotes AS user_upvotes,
        u.downvotes AS user_downvotes
    FROM votes v
    JOIN users u
        ON v.userid = u.id
    WHERE u.reputation >= 1000
)
SELECT
    vote_date,
    COUNT(vote_id) AS total_votes,
    SUM(bountyamount) AS total_bounty,
    AVG(reputation) AS avg_voter_reputation,
    COUNT(DISTINCT userid) AS distinct_voters,
    SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_votes,
    SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_votes,
    SUM(CASE WHEN votetypeid = 1 THEN bountyamount ELSE 0 END) AS upvote_bounty,
    SUM(CASE WHEN votetypeid = 2 THEN bountyamount ELSE 0 END) AS downvote_bounty
FROM vote_user
GROUP BY vote_date
ORDER BY vote_date DESC
