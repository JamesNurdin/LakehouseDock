WITH sales_per_store AS (
    SELECT
        ss.ss_store_id,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
        MIN(ss.ss_ts) AS first_transaction_ts,
        MAX(ss.ss_ts) AS last_transaction_ts
    FROM store_sales ss
    GROUP BY ss.ss_store_id
)
SELECT
    s.s_store_name,
    sp.total_quantity,
    sp.distinct_customers,
    sp.first_transaction_ts,
    sp.last_transaction_ts
FROM sales_per_store sp
INNER JOIN stores s
    ON sp.ss_store_id = s.s_store_id
ORDER BY sp.total_quantity DESC
LIMIT 100
