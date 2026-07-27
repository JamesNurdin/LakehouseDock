WITH filtered_sales AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_sold_time_sk,
        ws_ext_sales_price,
        ws_ext_ship_cost,
        ws_net_profit
    FROM web_sales
    WHERE ws_ext_sales_price > 1000
      AND ws_ext_ship_cost < 500
      AND ws_net_profit IS NOT NULL
),
filtered_returns AS (
    SELECT
        wr_order_number,
        wr_item_sk,
        wr_returned_time_sk,
        wr_return_quantity,
        wr_return_amt,
        wr_returning_customer_sk
    FROM web_returns
    WHERE wr_return_quantity > 0
      AND wr_return_amt > 50
      AND wr_returning_customer_sk IN (8926767, 4347687, 2619758)
)
SELECT
    td.t_hour,
    td.t_minute,
    td.t_am_pm,
    COUNT(DISTINCT fs.ws_order_number) AS distinct_orders,
    SUM(fs.ws_ext_sales_price) AS total_sales,
    AVG(fr.wr_return_amt) AS avg_return_amount,
    CASE
        WHEN SUM(fs.ws_ext_sales_price) > 500000 THEN 'Very High'
        WHEN SUM(fs.ws_ext_sales_price) > 200000 THEN 'High'
        ELSE 'Normal'
    END AS sales_category,
    MIN(fr.wr_return_quantity) AS min_return_qty,
    MAX(fr.wr_return_quantity) AS max_return_qty
FROM filtered_sales AS fs
JOIN filtered_returns AS fr
    ON fs.ws_order_number = fr.wr_order_number
   AND fs.ws_item_sk = fr.wr_item_sk
JOIN time_dim AS td
    ON fs.ws_sold_time_sk = td.t_time_sk
   AND fr.wr_returned_time_sk = td.t_time_sk
WHERE td.t_second IN (15, 18, 19)
  AND td.t_am_pm = 'PM'
GROUP BY td.t_hour, td.t_minute, td.t_am_pm
ORDER BY total_sales DESC
LIMIT 100
