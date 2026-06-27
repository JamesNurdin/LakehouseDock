WITH sales_by_time AS (
    SELECT
        time_dim.t_hour,
        time_dim.t_shift,
        SUM(catalog_sales.cs_ext_sales_price) AS total_sales,
        SUM(catalog_sales.cs_net_profit) AS total_profit,
        COUNT(*) AS transaction_count,
        AVG(catalog_sales.cs_quantity) AS avg_quantity
    FROM catalog_sales
    JOIN time_dim
        ON catalog_sales.cs_sold_time_sk = time_dim.t_time_sk
    WHERE catalog_sales.cs_quantity > 0
    GROUP BY time_dim.t_hour, time_dim.t_shift
)
SELECT
    t_hour,
    t_shift,
    total_sales,
    total_profit,
    transaction_count,
    avg_quantity,
    total_sales / NULLIF(transaction_count, 0) AS avg_sales_per_transaction
FROM sales_by_time
ORDER BY t_hour, t_shift
