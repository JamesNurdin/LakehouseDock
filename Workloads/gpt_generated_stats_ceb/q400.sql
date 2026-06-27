WITH badge_stats AS (
    SELECT
        b.userid,
        COUNT(*) AS badge_count,
        MIN(b.date) AS first_badge_date,
        MAX(b.date) AS last_badge_date
    FROM badges b
    GROUP BY b.userid
),
vote_stats AS (
    SELECT
        v.userid,
        COUNT(*) AS vote_count,
        COUNT(DISTINCT v.postid) AS distinct_posts_voted,
        SUM(v.bountyamount) AS total_bounty,
        AVG(v.votetypeid) AS avg_vote_type
    FROM votes v
    GROUP BY v.userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(b.badge_count, 0) AS badge_count,
    b.first_badge_date,
    b.last_badge_date,
    COALESCE(v.vote_count, 0) AS vote_count,
    v.distinct_posts_voted,
    v.total_bounty,
    v.avg_vote_type
FROM users u
LEFT JOIN badge_stats b ON b.userid = u.id
LEFT JOIN vote_stats v ON v.userid = u.id
WHERE u.reputation > 1000
ORDER BY u.reputation DESC
LIMIT 100
