WITH sales_by_customer_store AS (
    SELECT
        ss.ss_store_id,
        ss.ss_customer_id,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(ss.ss_transaction_id) AS transaction_count
    FROM store_sales ss
    GROUP BY ss.ss_store_id, ss.ss_customer_id
)
SELECT
    s.s_store_name,
    c.c_name,
    sbcs.total_quantity,
    sbcs.transaction_count
FROM sales_by_customer_store sbcs
JOIN stores s
    ON sbcs.ss_store_id = s.s_store_id
JOIN customers c
    ON sbcs.ss_customer_id = c.c_customer_id
ORDER BY sbcs.total_quantity DESC
LIMIT 10
