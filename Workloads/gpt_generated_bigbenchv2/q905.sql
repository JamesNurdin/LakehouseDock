WITH sales_month AS (
    SELECT
        ss_transaction_id,
        ss_customer_id,
        ss_store_id,
        ss_item_id,
        ss_quantity,
        CAST(ss_ts AS timestamp) AS ts,
        date_trunc('month', CAST(ss_ts AS timestamp)) AS month_start
    FROM store_sales
    WHERE ss_quantity > 0
)
SELECT
    s.s_store_name,
    sm.month_start,
    SUM(sm.ss_quantity) AS total_quantity,
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT sm.ss_customer_id) AS distinct_customers,
    AVG(sm.ss_quantity) AS avg_quantity_per_transaction
FROM sales_month sm
JOIN stores s
    ON sm.ss_store_id = s.s_store_id
GROUP BY
    s.s_store_name,
    sm.month_start
ORDER BY
    sm.month_start,
    total_quantity DESC
