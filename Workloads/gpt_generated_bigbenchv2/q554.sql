WITH sales_by_store AS (
    SELECT
        ss.ss_store_id,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS unique_customers,
        AVG(ss.ss_quantity) AS avg_quantity_per_transaction,
        COUNT(*) AS transaction_count
    FROM store_sales ss
    GROUP BY ss.ss_store_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    sb.total_quantity,
    sb.unique_customers,
    sb.avg_quantity_per_transaction,
    sb.transaction_count
FROM sales_by_store sb
JOIN stores s
    ON sb.ss_store_id = s.s_store_id
ORDER BY sb.total_quantity DESC
LIMIT 10
