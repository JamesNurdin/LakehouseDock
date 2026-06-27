WITH customer_totals AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_transaction_id) AS num_transactions
    FROM customers c
    JOIN web_sales ws
        ON ws.ws_customer_id = c.c_customer_id
    GROUP BY c.c_customer_id, c.c_name
)
SELECT
    ct.c_customer_id,
    ct.c_name,
    ct.total_quantity,
    ct.num_transactions,
    RANK() OVER (ORDER BY ct.total_quantity DESC) AS quantity_rank
FROM customer_totals ct
ORDER BY quantity_rank
LIMIT 10
