WITH monthly_sales AS (
    SELECT
        d_sold.d_year,
        d_sold.d_moy AS month,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_ship_delay_days,
        SUM(cs.cs_net_profit) / NULLIF(COUNT(*), 0) AS avg_profit_per_order
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    WHERE d_sold.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d_sold.d_year, d_sold.d_moy
)
SELECT
    d_year,
    month,
    num_orders,
    total_sales,
    total_profit,
    avg_ship_delay_days,
    avg_profit_per_order,
    SUM(total_profit) OVER (ORDER BY d_year, month ROWS UNBOUNDED PRECEDING) AS cumulative_profit
FROM monthly_sales
ORDER BY d_year, month
