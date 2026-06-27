WITH user_votes AS (
    SELECT
        users.id AS user_id,
        users.reputation,
        COUNT(votes.id) AS total_votes,
        SUM(CASE WHEN votes.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_votes,
        SUM(CASE WHEN votes.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_votes,
        COALESCE(SUM(votes.bountyamount), 0) AS total_bounty,
        COALESCE(AVG(votes.bountyamount), 0) AS avg_bounty,
        MIN(votes.creationdate) AS first_vote_date,
        MAX(votes.creationdate) AS last_vote_date
    FROM users
    LEFT JOIN votes
        ON votes.userid = users.id
    GROUP BY users.id, users.reputation
)
SELECT
    user_id,
    reputation,
    total_votes,
    upvote_votes,
    downvote_votes,
    total_bounty,
    avg_bounty,
    first_vote_date,
    last_vote_date
FROM user_votes
ORDER BY total_votes DESC
LIMIT 100
