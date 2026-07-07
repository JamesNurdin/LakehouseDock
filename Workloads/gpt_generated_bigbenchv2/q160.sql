WITH daily_customer_activity AS (
    SELECT
        wl_customer_id,
        date(cast(wl_timestamp AS timestamp)) AS activity_date,
        count(*) AS page_views,
        count(DISTINCT wl_item_id) AS distinct_items,
        sum(wl_key1) AS total_key1,
        avg(wl_key2) AS avg_key2
    FROM web_logs
    WHERE cast(wl_timestamp AS timestamp) >= timestamp '2023-01-01 00:00:00'
      AND cast(wl_timestamp AS timestamp) < timestamp '2024-01-01 00:00:00'
    GROUP BY wl_customer_id, date(cast(wl_timestamp AS timestamp))
)
SELECT
    wl_customer_id,
    activity_date,
    page_views,
    distinct_items,
    total_key1,
    avg_key2
FROM daily_customer_activity
ORDER BY wl_customer_id, activity_date DESC
LIMIT 100
