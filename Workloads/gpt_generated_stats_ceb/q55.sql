WITH comment_agg AS (
    SELECT
        c.userid AS user_id,
        SUM(c.score) AS total_comment_score,
        COUNT(*) AS comment_count
    FROM comments c
    GROUP BY c.userid
),
vote_agg AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS total_votes,
        SUM(v.bountyamount) AS total_bounty
    FROM votes v
    GROUP BY v.userid
),
user_engagement AS (
    SELECT
        u.id,
        u.reputation,
        u.creationdate,
        u.views,
        u.upvotes,
        u.downvotes,
        COALESCE(ca.total_comment_score, 0) AS total_comment_score,
        COALESCE(ca.comment_count, 0) AS comment_count,
        COALESCE(va.total_votes, 0) AS total_votes,
        COALESCE(va.total_bounty, 0) AS total_bounty,
        (COALESCE(ca.total_comment_score, 0) * 0.5
         + COALESCE(va.total_votes, 0) * 0.3
         + COALESCE(va.total_bounty, 0) * 0.2) AS engagement_score
    FROM users u
    LEFT JOIN comment_agg ca ON ca.user_id = u.id
    LEFT JOIN vote_agg va ON va.user_id = u.id
    WHERE u.reputation > 1000
)
SELECT
    ue.id,
    ue.reputation,
    ue.creationdate,
    ue.views,
    ue.upvotes,
    ue.downvotes,
    ue.total_comment_score,
    ue.comment_count,
    ue.total_votes,
    ue.total_bounty,
    ue.engagement_score,
    ROW_NUMBER() OVER (ORDER BY ue.engagement_score DESC) AS engagement_rank
FROM user_engagement ue
ORDER BY ue.engagement_score DESC
LIMIT 10
