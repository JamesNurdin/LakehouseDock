WITH vote_counts AS (
    SELECT
        votes.userid AS user_id,
        votes.votetypeid,
        COUNT(*) AS votes_per_type,
        SUM(COALESCE(votes.bountyamount, 0)) AS bounty_per_type,
        AVG(COALESCE(votes.bountyamount, 0)) AS avg_bounty_per_type
    FROM votes
    GROUP BY votes.userid, votes.votetypeid
),
user_summary AS (
    SELECT
        users.id AS user_id,
        users.reputation,
        users.creationdate,
        users.views,
        users.upvotes,
        users.downvotes,
        COUNT(votes.id) AS total_votes,
        SUM(COALESCE(votes.bountyamount, 0)) AS total_bounty,
        AVG(COALESCE(votes.bountyamount, 0)) AS avg_bounty
    FROM users
    LEFT JOIN votes ON votes.userid = users.id
    GROUP BY
        users.id,
        users.reputation,
        users.creationdate,
        users.views,
        users.upvotes,
        users.downvotes
),
top_vote_type AS (
    SELECT
        vc.user_id,
        vc.votetypeid,
        vc.votes_per_type,
        ROW_NUMBER() OVER (PARTITION BY vc.user_id ORDER BY vc.votes_per_type DESC) AS rn
    FROM vote_counts vc
)
SELECT
    us.user_id,
    us.reputation,
    us.creationdate,
    us.views,
    us.upvotes,
    us.downvotes,
    (us.upvotes - us.downvotes) AS net_votes_received,
    CASE
        WHEN us.downvotes > 0 THEN CAST(us.upvotes AS double) / us.downvotes
        ELSE NULL
    END AS up_down_ratio,
    us.total_votes,
    us.total_bounty,
    us.avg_bounty,
    tvt.votetypeid AS top_votetype,
    tvt.votes_per_type AS top_votetype_votes
FROM user_summary us
LEFT JOIN top_vote_type tvt
    ON tvt.user_id = us.user_id AND tvt.rn = 1
WHERE us.total_votes > 0
  AND us.reputation > 1000
ORDER BY us.total_votes DESC
LIMIT 100
