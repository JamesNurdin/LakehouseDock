WITH customer_store_sales AS (
    SELECT
        ss.ss_store_id,
        ss.ss_customer_id,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_transaction_id) AS transaction_count
    FROM store_sales ss
    GROUP BY ss.ss_store_id, ss.ss_customer_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    c.c_customer_id,
    c.c_name,
    css.total_quantity,
    css.transaction_count,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY css.total_quantity DESC) AS rn
FROM customer_store_sales css
JOIN stores s ON css.ss_store_id = s.s_store_id
JOIN customers c ON css.ss_customer_id = c.c_customer_id
WHERE css.total_quantity > 0
ORDER BY s.s_store_id, rn
LIMIT 20
