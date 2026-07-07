WITH daily_counts AS (
    SELECT
        wl.wl_customer_id,
        date(cast(wl.wl_timestamp AS timestamp)) AS view_date,
        count(*) AS daily_views
    FROM web_logs wl
    GROUP BY wl.wl_customer_id, date(cast(wl.wl_timestamp AS timestamp))
),
total_counts AS (
    SELECT
        wl.wl_customer_id,
        count(*) AS total_views
    FROM web_logs wl
    GROUP BY wl.wl_customer_id
)
SELECT
    d.wl_customer_id,
    d.view_date,
    d.daily_views,
    t.total_views,
    d.daily_views * 100.0 / t.total_views AS daily_view_pct
FROM daily_counts d
JOIN total_counts t
    ON d.wl_customer_id = t.wl_customer_id
ORDER BY d.daily_views DESC
LIMIT 100
