WITH user_aggregates AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate,
        u.views,
        u.upvotes,
        u.downvotes,
        COUNT(DISTINCT b.id) AS badge_count,
        COUNT(DISTINCT p.id) AS posthistory_count,
        MIN(b.date) AS first_badge_date,
        MIN(p.creationdate) AS first_posthistory_date,
        SUM(CASE WHEN p.posthistorytypeid = 1 THEN 1 ELSE 0 END) AS type1_actions,
        SUM(CASE WHEN p.posthistorytypeid = 2 THEN 1 ELSE 0 END) AS type2_actions
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    LEFT JOIN posthistory p
        ON p.userid = u.id
    GROUP BY u.id, u.reputation, u.creationdate, u.views, u.upvotes, u.downvotes
)
SELECT
    user_id,
    reputation,
    creationdate,
    views,
    upvotes,
    downvotes,
    badge_count,
    posthistory_count,
    type1_actions,
    type2_actions,
    badge_count * 1.0 / NULLIF(posthistory_count, 0) AS badge_to_posthistory_ratio,
    DATE_DIFF('day', CAST(first_badge_date AS date), CAST(first_posthistory_date AS date)) AS days_between_first_badge_and_posthistory,
    RANK() OVER (ORDER BY reputation DESC) AS reputation_rank
FROM user_aggregates
WHERE badge_count > 0
ORDER BY reputation DESC
LIMIT 100
