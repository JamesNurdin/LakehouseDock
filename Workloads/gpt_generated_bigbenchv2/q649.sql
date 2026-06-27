WITH store_agg AS (
    SELECT
        ss.ss_store_id,
        COUNT(DISTINCT ss.ss_transaction_id) AS transaction_count,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
        COUNT(DISTINCT ss.ss_item_id) AS distinct_items,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_quantity) AS avg_quantity
    FROM store_sales ss
    GROUP BY ss.ss_store_id
)
SELECT
    sa.ss_store_id,
    s.s_store_name,
    sa.total_quantity,
    (sa.total_quantity * 100.0) / SUM(sa.total_quantity) OVER () AS pct_total_quantity,
    sa.transaction_count,
    sa.distinct_customers,
    sa.distinct_items,
    sa.avg_quantity
FROM store_agg sa
JOIN stores s
    ON sa.ss_store_id = s.s_store_id
ORDER BY sa.total_quantity DESC
LIMIT 10
