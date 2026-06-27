WITH
    store_agg AS (
        SELECT
            ss.ss_customer_id AS c_customer_id,
            COUNT(ss.ss_transaction_id) AS store_txn_count,
            SUM(ss.ss_quantity) AS store_quantity
        FROM store_sales ss
        GROUP BY ss.ss_customer_id
    ),
    web_agg AS (
        SELECT
            ws.ws_customer_id AS c_customer_id,
            COUNT(ws.ws_transaction_id) AS web_txn_count,
            SUM(ws.ws_quantity) AS web_quantity
        FROM web_sales ws
        GROUP BY ws.ws_customer_id
    )
SELECT
    c.c_customer_id,
    c.c_name,
    COALESCE(s.store_txn_count, 0) AS store_txn_count,
    COALESCE(s.store_quantity, 0) AS store_quantity,
    COALESCE(w.web_txn_count, 0) AS web_txn_count,
    COALESCE(w.web_quantity, 0) AS web_quantity,
    COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
    COALESCE(s.store_txn_count, 0) + COALESCE(w.web_txn_count, 0) AS total_txn_count,
    CASE
        WHEN (COALESCE(s.store_txn_count, 0) + COALESCE(w.web_txn_count, 0)) > 0
        THEN (COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0)) * 1.0 /
             (COALESCE(s.store_txn_count, 0) + COALESCE(w.web_txn_count, 0))
        ELSE 0
    END AS avg_quantity_per_txn
FROM customers c
LEFT JOIN store_agg s
    ON s.c_customer_id = c.c_customer_id
LEFT JOIN web_agg w
    ON w.c_customer_id = c.c_customer_id
ORDER BY total_quantity DESC
LIMIT 100
