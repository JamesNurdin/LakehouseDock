WITH all_sales AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        ss.ss_quantity AS quantity,
        ss.ss_transaction_id AS transaction_id
    FROM customers c
    JOIN store_sales ss ON ss.ss_customer_id = c.c_customer_id
    UNION ALL
    SELECT
        c.c_customer_id,
        c.c_name,
        ws.ws_quantity AS quantity,
        ws.ws_transaction_id AS transaction_id
    FROM customers c
    JOIN web_sales ws ON ws.ws_customer_id = c.c_customer_id
)
SELECT
    c_customer_id,
    c_name,
    SUM(quantity) AS total_quantity,
    COUNT(transaction_id) AS total_transactions
FROM all_sales
GROUP BY c_customer_id, c_name
ORDER BY total_quantity DESC
LIMIT 100
