WITH badge_agg AS (
    SELECT
        b.userid AS userid,
        COUNT(b.id) AS badge_count,
        MIN(b.date) AS first_badge_date,
        MAX(b.date) AS last_badge_date
    FROM badges b
    GROUP BY b.userid
),
ph_agg AS (
    SELECT
        ph.userid AS userid,
        COUNT(ph.id) AS ph_count,
        MIN(ph.creationdate) AS first_ph_date,
        MAX(ph.creationdate) AS last_ph_date,
        COUNT(CASE WHEN ph.posthistorytypeid = 1 THEN 1 END) AS post_creation_count,
        COUNT(CASE WHEN ph.posthistorytypeid = 2 THEN 1 END) AS post_edit_count
    FROM posthistory ph
    GROUP BY ph.userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate AS user_creation_date,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(badge_agg.badge_count, 0) AS badge_count,
    COALESCE(ph_agg.ph_count, 0) AS posthistory_count,
    COALESCE(ph_agg.post_creation_count, 0) AS post_creation_count,
    COALESCE(ph_agg.post_edit_count, 0) AS post_edit_count,
    CASE WHEN u.downvotes = 0 THEN NULL ELSE CAST(u.upvotes AS double) / u.downvotes END AS upvote_downvote_ratio,
    CASE
        WHEN badge_agg.first_badge_date IS NOT NULL AND ph_agg.first_ph_date IS NOT NULL
        THEN date_diff('day', CAST(badge_agg.first_badge_date AS date), CAST(ph_agg.first_ph_date AS date))
        ELSE NULL
    END AS days_between_first_badge_and_posthistory
FROM users u
LEFT JOIN badge_agg ON badge_agg.userid = u.id
LEFT JOIN ph_agg ON ph_agg.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
