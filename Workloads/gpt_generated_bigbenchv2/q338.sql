WITH sales_with_date AS (
    SELECT
        ss_store_id,
        ss_customer_id,
        ss_quantity,
        date(CAST(ss_ts AS TIMESTAMP)) AS transaction_date
    FROM store_sales
),
aggregated AS (
    SELECT
        swd.ss_store_id,
        swd.transaction_date,
        SUM(swd.ss_quantity) AS total_quantity,
        COUNT(DISTINCT swd.ss_customer_id) AS distinct_customers,
        COUNT(*) AS total_transactions,
        AVG(swd.ss_quantity) AS avg_quantity_per_transaction
    FROM sales_with_date swd
    GROUP BY
        swd.ss_store_id,
        swd.transaction_date
)
SELECT
    s.s_store_name,
    agg.transaction_date,
    agg.total_quantity,
    agg.distinct_customers,
    agg.total_transactions,
    agg.avg_quantity_per_transaction,
    RANK() OVER (PARTITION BY agg.transaction_date ORDER BY agg.total_quantity DESC) AS rank_by_quantity
FROM aggregated agg
JOIN stores s
    ON agg.ss_store_id = s.s_store_id
ORDER BY
    agg.transaction_date DESC,
    rank_by_quantity
LIMIT 20
