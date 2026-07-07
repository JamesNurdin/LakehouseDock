WITH store_aggregates AS (
    SELECT
        ss.ss_store_id,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(ss.ss_transaction_id) AS transaction_count,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    GROUP BY ss.ss_store_id
)
SELECT
    s.s_store_name,
    sa.total_quantity,
    sa.transaction_count,
    sa.distinct_customers
FROM store_aggregates sa
JOIN stores s
    ON sa.ss_store_id = s.s_store_id
ORDER BY sa.total_quantity DESC
LIMIT 10
