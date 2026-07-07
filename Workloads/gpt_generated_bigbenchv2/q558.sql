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
    COALESCE(sa.store_txn_cnt, 0) AS store_txn_cnt,
    COALESCE(sa.store_qty, 0) AS store_qty,
    COALESCE(wa.web_txn_cnt, 0) AS web_txn_cnt,
    COALESCE(wa.web_qty, 0) AS web_qty,
    COALESCE(sa.store_qty, 0) + COALESCE(wa.web_qty, 0) AS total_qty
FROM customers AS c
LEFT JOIN store_agg AS sa
    ON sa.ss_customer_id = c.c_customer_id
LEFT JOIN web_agg AS wa
    ON wa.ws_customer_id = c.c_customer_id
ORDER BY total_qty DESC
LIMIT 100
