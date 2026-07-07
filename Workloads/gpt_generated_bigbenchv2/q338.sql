WITH customer_page_views AS (
    SELECT
        wl_customer_id,
        wl_webpage_name,
        COUNT(*) AS view_count,
        MIN(CAST(wl_timestamp AS timestamp)) AS first_view,
        MAX(CAST(wl_timestamp AS timestamp)) AS last_view
    FROM web_logs
    WHERE CAST(wl_timestamp AS timestamp) >= TIMESTAMP '2023-01-01'
      AND CAST(wl_timestamp AS timestamp) < TIMESTAMP '2024-01-01'
    GROUP BY wl_customer_id, wl_webpage_name
)
SELECT
    wl.wl_id,
    wl.wl_customer_id,
    wl.wl_item_id,
    wl.wl_webpage_name,
    wl.wl_timestamp,
    cpv.view_count,
    cpv.first_view,
    cpv.last_view
FROM web_logs wl
JOIN customer_page_views cpv
    ON wl.wl_customer_id = cpv.wl_customer_id
   AND wl.wl_webpage_name = cpv.wl_webpage_name
WHERE cpv.view_count > 10
ORDER BY cpv.view_count DESC, cpv.first_view ASC
LIMIT 100
