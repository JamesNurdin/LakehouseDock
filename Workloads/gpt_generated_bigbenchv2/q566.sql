WITH customer_views AS (
    SELECT
        wl_customer_id,
        count(*) AS total_views,
        max(cast(wl_timestamp AS timestamp)) AS latest_ts
    FROM web_logs
    GROUP BY wl_customer_id
),
top_customers AS (
    SELECT wl_customer_id, total_views, latest_ts
    FROM customer_views
    ORDER BY total_views DESC
    LIMIT 5
)
SELECT
    wl.wl_customer_id,
    wl.wl_item_id,
    wl.wl_webpage_name,
    cast(wl.wl_timestamp AS timestamp) AS visit_timestamp,
    tc.total_views
FROM web_logs wl
JOIN top_customers tc
    ON wl.wl_customer_id = tc.wl_customer_id
    AND cast(wl.wl_timestamp AS timestamp) = tc.latest_ts
ORDER BY tc.total_views DESC
