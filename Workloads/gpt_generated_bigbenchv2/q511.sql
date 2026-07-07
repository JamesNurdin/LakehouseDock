WITH customer_product_views AS (
    SELECT
        wl_customer_id,
        COUNT(DISTINCT wl_item_id) AS distinct_items,
        COUNT(*) AS total_visits
    FROM web_logs
    WHERE wl_webpage_name = 'product_detail'
    GROUP BY wl_customer_id
)
SELECT
    w.wl_id,
    w.wl_customer_id,
    w.wl_item_id,
    w.wl_webpage_name,
    w.wl_timestamp,
    cpv.distinct_items,
    cpv.total_visits
FROM web_logs w
JOIN customer_product_views cpv
    ON w.wl_customer_id = cpv.wl_customer_id
WHERE w.wl_webpage_name = 'product_detail'
ORDER BY cpv.distinct_items DESC,
         cpv.total_visits DESC,
         w.wl_timestamp DESC
LIMIT 100
