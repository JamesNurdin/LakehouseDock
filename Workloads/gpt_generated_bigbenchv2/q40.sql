WITH sales_with_customer AS (
    SELECT
        ss.ss_customer_id,
        c.c_name,
        ss.ss_quantity,
        ss.ss_store_id,
        ss.ss_ts
    FROM store_sales ss
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
),
monthly_customer_sales AS (
    SELECT
        swc.ss_customer_id,
        swc.c_name,
        DATE_TRUNC('month', CAST(swc.ss_ts AS timestamp)) AS month,
        SUM(swc.ss_quantity) AS total_quantity,
        COUNT(DISTINCT swc.ss_store_id) AS distinct_stores,
        AVG(swc.ss_quantity) AS avg_quantity_per_line
    FROM sales_with_customer swc
    GROUP BY
        swc.ss_customer_id,
        swc.c_name,
        DATE_TRUNC('month', CAST(swc.ss_ts AS timestamp))
)
SELECT
    mcs.ss_customer_id,
    mcs.c_name,
    mcs.month,
    mcs.total_quantity,
    mcs.distinct_stores,
    mcs.avg_quantity_per_line,
    RANK() OVER (PARTITION BY mcs.month ORDER BY mcs.total_quantity DESC) AS monthly_quantity_rank
FROM monthly_customer_sales mcs
WHERE mcs.total_quantity > 0
ORDER BY mcs.month DESC, monthly_quantity_rank
LIMIT 20
