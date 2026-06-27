WITH user_agg AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(DISTINCT b.id) AS badge_count,
        COUNT(DISTINCT ph.id) AS posthistory_count,
        COUNT(DISTINCT v.id) AS vote_count,
        SUM(v.bountyamount) AS total_bounty,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast,
        MIN(b.date) AS first_badge_date,
        MIN(v.creationdate) AS first_vote_date,
        MIN(ph.creationdate) AS first_posthistory_date
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    LEFT JOIN posthistory ph ON ph.userid = u.id
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id, u.reputation
)
SELECT
    user_id,
    reputation,
    badge_count,
    posthistory_count,
    vote_count,
    total_bounty,
    upvote_cast,
    downvote_cast,
    date_diff('day', first_badge_date, first_vote_date) AS days_between_badge_and_vote,
    date_diff('day', first_vote_date, first_posthistory_date) AS days_between_vote_and_posthistory
FROM user_agg
WHERE badge_count > 0
ORDER BY vote_count DESC
LIMIT 100
