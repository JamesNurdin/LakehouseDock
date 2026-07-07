WITH customer_pageviews AS (
    SELECT
        wl_customer_id,
        COUNT(*) AS total_page_views,
        COUNT(DISTINCT wl_item_id) AS distinct_items_viewed
    FROM web_logs
    WHERE CAST(wl_timestamp AS timestamp) >= TIMESTAMP '2023-01-01'
      AND CAST(wl_timestamp AS timestamp) < TIMESTAMP '2023-02-01'
    GROUP BY wl_customer_id
),
customer_last_view AS (
    SELECT
        wl_customer_id,
        MAX(CAST(wl_timestamp AS timestamp)) AS last_view_timestamp
    FROM web_logs
    WHERE CAST(wl_timestamp AS timestamp) >= TIMESTAMP '2023-01-01'
      AND CAST(wl_timestamp AS timestamp) < TIMESTAMP '2023-02-01'
    GROUP BY wl_customer_id
)
SELECT
    cp.wl_customer_id,
    cp.total_page_views,
    cp.distinct_items_viewed,
    clv.last_view_timestamp
FROM customer_pageviews cp
JOIN customer_last_view clv
    ON cp.wl_customer_id = clv.wl_customer_id
ORDER BY cp.total_page_views DESC
LIMIT 10
