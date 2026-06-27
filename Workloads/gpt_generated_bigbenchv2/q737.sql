WITH monthly_sales AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        date_trunc('month', CAST(ws.ws_ts AS timestamp)) AS month,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_transaction_id) AS transaction_count
    FROM web_sales ws
    JOIN customers c
        ON ws.ws_customer_id = c.c_customer_id
    GROUP BY
        c.c_customer_id,
        c.c_name,
        date_trunc('month', CAST(ws.ws_ts AS timestamp))
),
ranked_sales AS (
    SELECT
        month,
        c_name,
        total_quantity,
        transaction_count,
        ROW_NUMBER() OVER (PARTITION BY month ORDER BY total_quantity DESC) AS month_rank
    FROM monthly_sales
)
SELECT
    month,
    c_name,
    total_quantity,
    transaction_count,
    month_rank
FROM ranked_sales
WHERE month_rank <= 5
ORDER BY month, month_rank
