WITH customer_sales AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        ss.ss_transaction_id,
        ss.ss_quantity,
        ss.ss_item_id
    FROM store_sales ss
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
),
customer_agg AS (
    SELECT
        cs.c_customer_id,
        cs.c_name,
        COUNT(DISTINCT cs.ss_transaction_id) AS num_transactions,
        SUM(cs.ss_quantity) AS total_quantity,
        COUNT(DISTINCT cs.ss_item_id) AS distinct_items,
        AVG(cs.ss_quantity) AS avg_quantity_per_transaction
    FROM customer_sales cs
    GROUP BY cs.c_customer_id, cs.c_name
)
SELECT
    ca.c_customer_id,
    ca.c_name,
    ca.num_transactions,
    ca.total_quantity,
    ca.distinct_items,
    ca.avg_quantity_per_transaction,
    RANK() OVER (ORDER BY ca.total_quantity DESC) AS quantity_rank,
    SUM(ca.total_quantity) OVER (
        ORDER BY ca.total_quantity DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_quantity
FROM customer_agg ca
ORDER BY ca.total_quantity DESC
LIMIT 10
