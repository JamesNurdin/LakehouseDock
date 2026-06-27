WITH store_agg AS (
    SELECT
        ss_customer_id,
        COUNT(*) AS store_txn_count,
        SUM(ss_quantity) AS store_total_quantity,
        COUNT(DISTINCT ss_item_id) AS store_distinct_items
    FROM store_sales
    GROUP BY ss_customer_id
),
web_agg AS (
    SELECT
        ws_customer_id,
        COUNT(*) AS web_txn_count,
        SUM(ws_quantity) AS web_total_quantity,
        COUNT(DISTINCT ws_item_id) AS web_distinct_items
    FROM web_sales
    GROUP BY ws_customer_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    COALESCE(sa.store_txn_count, 0) AS store_txn_count,
    COALESCE(sa.store_total_quantity, 0) AS store_total_quantity,
    COALESCE(sa.store_distinct_items, 0) AS store_distinct_items,
    COALESCE(wa.web_txn_count, 0) AS web_txn_count,
    COALESCE(wa.web_total_quantity, 0) AS web_total_quantity,
    COALESCE(wa.web_distinct_items, 0) AS web_distinct_items,
    COALESCE(sa.store_total_quantity, 0) + COALESCE(wa.web_total_quantity, 0) AS total_quantity,
    COALESCE(sa.store_txn_count, 0) + COALESCE(wa.web_txn_count, 0) AS total_txn_count
FROM customers c
LEFT JOIN store_agg sa
    ON sa.ss_customer_id = c.c_customer_id
LEFT JOIN web_agg wa
    ON wa.ws_customer_id = c.c_customer_id
ORDER BY total_quantity DESC
LIMIT 10
