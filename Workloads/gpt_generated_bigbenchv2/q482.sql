WITH store_agg AS (
    SELECT
        ss_customer_id AS customer_id,
        COUNT(ss_transaction_id) AS store_transactions,
        SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_customer_id
),
web_agg AS (
    SELECT
        ws_customer_id AS customer_id,
        COUNT(ws_transaction_id) AS web_transactions,
        SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_customer_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    COALESCE(s.store_transactions, 0) AS store_transactions,
    COALESCE(s.store_quantity, 0) AS store_quantity,
    COALESCE(w.web_transactions, 0) AS web_transactions,
    COALESCE(w.web_quantity, 0) AS web_quantity,
    COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
    COALESCE(s.store_transactions, 0) + COALESCE(w.web_transactions, 0) AS total_transactions
FROM customers c
LEFT JOIN store_agg s
    ON s.customer_id = c.c_customer_id
LEFT JOIN web_agg w
    ON w.customer_id = c.c_customer_id
ORDER BY total_quantity DESC
LIMIT 10
