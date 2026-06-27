/*
  Analytical query: badge activity and user engagement metrics per user.
  - Joins badges to users on the only valid key (badges.userid = users.id).
  - Filters to users with reputation >= 1000 (non‑date filter).
  - Aggregates badge counts and badge date range per user.
  - Computes net votes, total votes and up‑vote ratio from the user columns.
  - Ranks users by badge count.
*/
WITH user_badge_stats AS (
    SELECT
        users.id AS user_id,
        users.reputation,
        users.views,
        users.upvotes,
        users.downvotes,
        COUNT(badges.id) AS badge_count,
        MIN(badges.date) AS first_badge_date,
        MAX(badges.date) AS last_badge_date
    FROM badges
    JOIN users ON badges.userid = users.id
    WHERE users.reputation >= 1000
    GROUP BY
        users.id,
        users.reputation,
        users.views,
        users.upvotes,
        users.downvotes
)
SELECT
    user_id,
    reputation,
    badge_count,
    first_badge_date,
    last_badge_date,
    (upvotes - downvotes) AS net_votes,
    (upvotes + downvotes) AS total_votes,
    CASE
        WHEN (upvotes + downvotes) > 0 THEN upvotes * 1.0 / (upvotes + downvotes)
        ELSE NULL
    END AS upvote_ratio,
    rank() OVER (ORDER BY badge_count DESC) AS badge_rank
FROM user_badge_stats
ORDER BY badge_count DESC, reputation DESC
LIMIT 100
