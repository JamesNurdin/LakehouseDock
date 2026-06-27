WITH badge_counts AS (
    SELECT
        userid,
        COUNT(*) AS badge_count,
        MIN(date) AS first_badge_date,
        MAX(date) AS last_badge_date
    FROM badges
    GROUP BY userid
),
comment_stats AS (
    SELECT
        userid,
        COUNT(*) AS comment_count,
        AVG(score) AS avg_comment_score,
        MIN(creationdate) AS first_comment_date,
        MAX(creationdate) AS last_comment_date
    FROM comments
    GROUP BY userid
),
vote_stats AS (
    SELECT
        userid,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast_count,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast_count,
        SUM(bountyamount) AS total_bounty_amount,
        MIN(creationdate) AS first_vote_date,
        MAX(creationdate) AS last_vote_date
    FROM votes
    GROUP BY userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate AS user_creation_date,
    u.views,
    u.upvotes AS user_upvotes,
    u.downvotes AS user_downvotes,
    COALESCE(bc.badge_count, 0) AS badge_count,
    bc.first_badge_date,
    bc.last_badge_date,
    COALESCE(cs.comment_count, 0) AS comment_count,
    cs.avg_comment_score,
    cs.first_comment_date,
    cs.last_comment_date,
    COALESCE(vs.vote_count, 0) AS vote_count,
    vs.upvote_cast_count,
    vs.downvote_cast_count,
    vs.total_bounty_amount,
    vs.first_vote_date,
    vs.last_vote_date
FROM users u
LEFT JOIN badge_counts bc ON bc.userid = u.id
LEFT JOIN comment_stats cs ON cs.userid = u.id
LEFT JOIN vote_stats vs ON vs.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
