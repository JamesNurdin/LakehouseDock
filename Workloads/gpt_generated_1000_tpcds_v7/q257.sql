WITH sales_returns AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        d.d_date AS sale_date,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        SUM(wr.wr_return_amt) AS total_returns,
        SUM(wr.wr_fee) AS total_return_fees
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr
      ON wr.wr_returned_date_sk = d.d_date_sk
     AND wr.wr_returned_time_sk = t.t_time_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 8 AND 18
      AND cs.cs_net_paid_inc_ship_tax > 500
      AND w.w_warehouse_sq_ft > 200000
      AND wr.wr_fee > 20
    GROUP BY w.w_warehouse_name, d.d_date
)
SELECT
    warehouse_name,
    sale_date,
    total_sales,
    total_profit,
    total_returns,
    total_return_fees,
    (total_profit - total_return_fees) / NULLIF(total_sales, 0) AS profit_margin,
    total_sales / NULLIF(num_orders, 0) AS avg_sale_per_order
FROM sales_returns
WHERE total_sales > 10000
  AND total_returns > 0
ORDER BY total_sales DESC
LIMIT 100
