WITH filtered_sales AS (
    SELECT
        cs_sold_time_sk,
        cs_item_sk,
        cs_order_number,
        cs_quantity,
        cs_sales_price,
        cs_ext_discount_amt,
        cs_ext_ship_cost,
        cs_net_paid,
        cs_net_profit
    FROM tpcds.catalog_sales
    WHERE cs_sales_price >= 20.00
        AND cs_ext_discount_amt BETWEEN 500.00 AND 2000.00
        AND cs_ext_ship_cost < 1000.00
        AND cs_quantity >= 2
        AND cs_net_profit > 0
)
SELECT
    td.t_hour,
    td.t_meal_time,
    COUNT(DISTINCT fs.cs_order_number) AS distinct_orders,
    SUM(fs.cs_net_paid) AS total_net_paid,
    AVG(fs.cs_sales_price) AS avg_sales_price,
    MIN(fs.cs_ext_discount_amt) AS min_discount_amt,
    MAX(fs.cs_ext_ship_cost) AS max_ship_cost
FROM filtered_sales AS fs
JOIN tpcds.time_dim AS td
    ON fs.cs_sold_time_sk = td.t_time_sk
WHERE td.t_minute IN (6, 17, 14)
    AND td.t_hour BETWEEN 6 AND 20
    AND td.t_meal_time = 'breakfast'
GROUP BY td.t_hour, td.t_meal_time
ORDER BY total_net_paid DESC
LIMIT 100
