WITH badge_agg AS (
    SELECT
        b.userid,
        date_trunc('month', b.date) AS month,
        COUNT(b.id) AS badge_count
    FROM badges b
    GROUP BY b.userid, date_trunc('month', b.date)
),
ph_agg AS (
    SELECT
        ph.userid,
        date_trunc('month', ph.creationdate) AS month,
        COUNT(ph.id) AS ph_count,
        COUNT(DISTINCT ph.posthistorytypeid) AS distinct_ph_type_count
    FROM posthistory ph
    GROUP BY ph.userid, date_trunc('month', ph.creationdate)
),
combined AS (
    SELECT
        COALESCE(b.userid, p.userid) AS userid,
        COALESCE(b.month, p.month) AS month,
        b.badge_count,
        p.ph_count,
        p.distinct_ph_type_count
    FROM badge_agg b
    FULL OUTER JOIN ph_agg p
        ON b.userid = p.userid
        AND b.month = p.month
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.views,
    u.upvotes,
    u.downvotes,
    c.month,
    COALESCE(c.badge_count, 0) AS badge_count,
    COALESCE(c.ph_count, 0) AS posthistory_event_count,
    COALESCE(c.distinct_ph_type_count, 0) AS distinct_posthistory_type_count,
    (u.reputation * 1.0) / NULLIF(u.views, 0) AS reputation_per_view
FROM users u
LEFT JOIN combined c
    ON c.userid = u.id
ORDER BY u.reputation DESC, c.month DESC
LIMIT 200
