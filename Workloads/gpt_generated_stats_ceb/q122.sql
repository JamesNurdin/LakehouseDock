WITH badge_agg AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
vote_agg AS (
    SELECT
        userid,
        COUNT(*) AS vote_count,
        SUM(COALESCE(bountyamount, 0)) AS total_bounty_amount,
        COUNT(DISTINCT votetypeid) AS distinct_vote_type_count
    FROM votes
    GROUP BY userid
),
user_metrics AS (
    SELECT
        u.id,
        u.reputation,
        u.creationdate,
        u.views,
        u.upvotes,
        u.downvotes,
        COALESCE(b.badge_count, 0) AS badge_count,
        COALESCE(v.vote_count, 0) AS vote_count,
        COALESCE(v.total_bounty_amount, 0) AS total_bounty_amount,
        COALESCE(v.distinct_vote_type_count, 0) AS distinct_vote_type_count
    FROM users u
    LEFT JOIN badge_agg b ON b.userid = u.id
    LEFT JOIN vote_agg v ON v.userid = u.id
)
SELECT
    user_id,
    reputation,
    creationdate,
    views,
    upvotes,
    downvotes,
    badge_count,
    vote_count,
    total_bounty_amount,
    distinct_vote_type_count,
    user_rank
FROM (
    SELECT
        id AS user_id,
        reputation,
        creationdate,
        views,
        upvotes,
        downvotes,
        badge_count,
        vote_count,
        total_bounty_amount,
        distinct_vote_type_count,
        ROW_NUMBER() OVER (ORDER BY badge_count DESC, vote_count DESC) AS user_rank
    FROM user_metrics
) ranked
WHERE user_rank <= 10
ORDER BY user_rank
