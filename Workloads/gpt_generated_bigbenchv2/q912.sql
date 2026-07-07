WITH customer_agg AS (
    SELECT
        wl_customer_id,
        COUNT(*) AS total_visits,
        COUNT(DISTINCT wl_item_id) AS distinct_items_viewed
    FROM web_logs
    GROUP BY wl_customer_id
)
SELECT
    w.wl_id,
    w.wl_customer_id,
    w.wl_item_id,
    w.wl_webpage_name,
    w.wl_timestamp,
    ca.total_visits,
    ca.distinct_items_viewed
FROM web_logs AS w
JOIN customer_agg AS ca
    ON w.wl_customer_id = ca.wl_customer_id
WHERE ca.total_visits > 5
ORDER BY ca.total_visits DESC
LIMIT 100
