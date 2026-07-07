WITH customer_store_sales AS (
    SELECT
        ss.ss_customer_id,
        ss.ss_store_id,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    GROUP BY ss.ss_customer_id, ss.ss_store_id
)
SELECT
    c.c_name,
    cs.ss_store_id,
    cs.total_quantity
FROM customer_store_sales cs
JOIN customers c
    ON cs.ss_customer_id = c.c_customer_id
ORDER BY cs.total_quantity DESC
LIMIT 100
