WITH store_agg AS (
    SELECT
        ss_customer_id,
        COUNT(ss_transaction_id) AS store_txn_cnt,
        SUM(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_customer_id
),
web_agg AS (
    SELECT
        ws_customer_id,
        COUNT(ws_transaction_id) AS web_txn_cnt,
        SUM(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_customer_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    COALESCE(sa.store_qty, 0) AS store_quantity,
    COALESCE(sa.store_txn_cnt, 0) AS store_transactions,
    COALESCE(wa.web_qty, 0) AS web_quantity,
    COALESCE(wa.web_txn_cnt, 0) AS web_transactions,
    COALESCE(sa.store_qty, 0) + COALESCE(wa.web_qty, 0) AS total_quantity,
    COALESCE(sa.store_txn_cnt, 0) + COALESCE(wa.web_txn_cnt, 0) AS total_transactions
FROM customers c
LEFT JOIN store_agg sa
    ON sa.ss_customer_id = c.c_customer_id
LEFT JOIN web_agg wa
    ON wa.ws_customer_id = c.c_customer_id
WHERE COALESCE(sa.store_qty, 0) + COALESCE(wa.web_qty, 0) > 0
ORDER BY total_quantity DESC
LIMIT 100
