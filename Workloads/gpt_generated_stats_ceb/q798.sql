WITH badge_counts AS (
    SELECT
        badges.userid,
        COUNT(badges.id) AS badge_cnt,
        MIN(badges.date) AS first_badge_date,
        MAX(badges.date) AS last_badge_date
    FROM badges
    GROUP BY badges.userid
)
SELECT
    users.id AS user_id,
    users.reputation,
    users.creationdate,
    users.views,
    users.upvotes,
    users.downvotes,
    badge_counts.badge_cnt,
    badge_counts.first_badge_date,
    badge_counts.last_badge_date,
    DATE_DIFF('day', users.creationdate, badge_counts.last_badge_date) AS days_to_last_badge,
    RANK() OVER (ORDER BY badge_counts.badge_cnt DESC) AS badge_rank,
    ROW_NUMBER() OVER (ORDER BY users.reputation DESC) AS reputation_rank
FROM users
LEFT JOIN badge_counts
    ON badge_counts.userid = users.id
WHERE badge_counts.badge_cnt IS NOT NULL
ORDER BY badge_counts.badge_cnt DESC
LIMIT 100
