WITH store_agg AS (
    SELECT
        ss_customer_id,
        COUNT(ss_transaction_id) AS store_txn_count,
        SUM(ss_quantity) AS store_quantity_total
    FROM store_sales
    GROUP BY ss_customer_id
),
web_agg AS (
    SELECT
        ws_customer_id,
        COUNT(ws_transaction_id) AS web_txn_count,
        SUM(ws_quantity) AS web_quantity_total
    FROM web_sales
    GROUP BY ws_customer_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    COALESCE(sa.store_txn_count, 0) AS store_txn_count,
    COALESCE(sa.store_quantity_total, 0) AS store_quantity_total,
    COALESCE(wa.web_txn_count, 0) AS web_txn_count,
    COALESCE(wa.web_quantity_total, 0) AS web_quantity_total,
    COALESCE(sa.store_quantity_total, 0) + COALESCE(wa.web_quantity_total, 0) AS total_quantity,
    COALESCE(sa.store_txn_count, 0) + COALESCE(wa.web_txn_count, 0) AS total_txn_count
FROM customers c
LEFT JOIN store_agg sa
    ON sa.ss_customer_id = c.c_customer_id
LEFT JOIN web_agg wa
    ON wa.ws_customer_id = c.c_customer_id
ORDER BY total_quantity DESC
LIMIT 10
