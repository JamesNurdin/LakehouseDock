WITH filtered_logs AS (
    SELECT wl_webpage_name, wl_customer_id, wl_item_id
    FROM web_logs
    WHERE wl_timestamp LIKE '2023-%'
)
SELECT wl_webpage_name,
       COUNT(*) AS page_views,
       COUNT(DISTINCT wl_customer_id) AS unique_customers,
       COUNT(DISTINCT wl_item_id) AS unique_items
FROM filtered_logs
GROUP BY wl_webpage_name
ORDER BY page_views DESC
LIMIT 10
