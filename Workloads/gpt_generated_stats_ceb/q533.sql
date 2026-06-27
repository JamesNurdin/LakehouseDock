WITH user_posts AS (
    SELECT
        u.id,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_score,
        COALESCE(AVG(p.score), 0) AS avg_score
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id,
        COUNT(b.id) AS badge_count,
        MIN(b.date) AS first_badge_date
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
votes_cast AS (
    SELECT
        u.id,
        COUNT(v.id) AS votes_cast_count,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty_cast
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
votes_received AS (
    SELECT
        u.id,
        COUNT(v.id) AS votes_received_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_score, 0) AS total_post_score,
    COALESCE(up.avg_score, 0) AS avg_post_score,
    COALESCE(ub.badge_count, 0) AS badge_count,
    ub.first_badge_date,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast,
    COALESCE(vc.total_bounty_cast, 0) AS total_bounty_cast,
    COALESCE(vr.votes_received_count, 0) AS votes_received,
    date_diff('day', u.creationdate, current_timestamp) AS days_since_join,
    CASE 
        WHEN date_diff('day', u.creationdate, current_timestamp) = 0 THEN NULL
        ELSE COALESCE(up.post_count, 0) / CAST(date_diff('day', u.creationdate, current_timestamp) AS double)
    END AS posts_per_day
FROM users u
LEFT JOIN user_posts up ON up.id = u.id
LEFT JOIN user_badges ub ON ub.id = u.id
LEFT JOIN votes_cast vc ON vc.id = u.id
LEFT JOIN votes_received vr ON vr.id = u.id
ORDER BY u.reputation DESC
LIMIT 100
