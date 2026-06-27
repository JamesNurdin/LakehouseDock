WITH badge_stats AS (
    SELECT
        users.id,
        COUNT(badges.id) AS badge_count,
        MIN(badges.date) AS first_badge_date
    FROM users
    LEFT JOIN badges ON badges.userid = users.id
    GROUP BY users.id
),
vote_stats AS (
    SELECT
        users.id,
        COUNT(votes.id) AS vote_count,
        SUM(votes.bountyamount) AS total_bounty,
        COUNT(DISTINCT votes.postid) AS distinct_posts_voted,
        MAX(votes.creationdate) AS last_vote_date
    FROM users
    LEFT JOIN votes ON votes.userid = users.id
    GROUP BY users.id
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    bs.badge_count,
    bs.first_badge_date,
    vs.vote_count,
    vs.total_bounty,
    vs.distinct_posts_voted,
    vs.last_vote_date,
    (bs.badge_count + vs.vote_count) AS total_activity,
    CASE WHEN u.downvotes = 0 THEN NULL ELSE CAST(u.upvotes AS double) / u.downvotes END AS upvote_downvote_ratio,
    RANK() OVER (ORDER BY bs.badge_count DESC) AS badge_rank
FROM users u
LEFT JOIN badge_stats bs ON bs.id = u.id
LEFT JOIN vote_stats vs ON vs.id = u.id
ORDER BY total_activity DESC
LIMIT 100
