WITH badge_agg AS (
    SELECT userid,
           COUNT(*) AS badge_count,
           MIN(date) AS first_badge_date
    FROM badges
    GROUP BY userid
),
posthistory_agg AS (
    SELECT userid,
           COUNT(*) AS posthistory_count,
           MIN(creationdate) AS first_ph_date
    FROM posthistory
    GROUP BY userid
),
vote_agg AS (
    SELECT userid,
           COUNT(*) AS vote_count,
           SUM(COALESCE(bountyamount, 0)) AS total_bounty,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
           SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count,
           MIN(creationdate) AS first_vote_date
    FROM votes
    GROUP BY userid
),
first_activity AS (
    SELECT userid,
           MIN(activity_date) AS first_activity_date
    FROM (
        SELECT userid, date AS activity_date FROM badges
        UNION ALL
        SELECT userid, creationdate FROM posthistory
        UNION ALL
        SELECT userid, creationdate FROM votes
    ) t
    GROUP BY userid
)
SELECT 
    u.id AS user_id,
    u.reputation,
    u.creationdate AS user_creation_date,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.total_bounty, 0) AS total_bounty,
    COALESCE(v.upvote_count, 0) AS upvote_votes_cast,
    COALESCE(v.downvote_count, 0) AS downvote_votes_cast,
    fa.first_activity_date,
    ROW_NUMBER() OVER (ORDER BY (COALESCE(b.badge_count, 0) * 2 + COALESCE(v.vote_count, 0)) DESC) AS activity_rank
FROM users u
LEFT JOIN badge_agg b ON b.userid = u.id
LEFT JOIN posthistory_agg ph ON ph.userid = u.id
LEFT JOIN vote_agg v ON v.userid = u.id
LEFT JOIN first_activity fa ON fa.userid = u.id
WHERE u.reputation >= 1000
ORDER BY activity_rank
LIMIT 20
