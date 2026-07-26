WITH daily_sales AS (
  SELECT d.d_date,
         SUM(ss.ss_net_profit) AS total_sales_profit,
         AVG(hd.hd_vehicle_count) AS avg_vehicle_count_sales
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  GROUP BY d.d_date
),
 daily_returns AS (
  SELECT d.d_date,
         SUM(cr.cr_net_loss) AS total_return_loss,
         AVG(hd.hd_vehicle_count) AS avg_vehicle_count_returns
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  GROUP BY d.d_date
)
SELECT d.d_date,
       COALESCE(s.total_sales_profit, 0) AS sales_profit,
       COALESCE(r.total_return_loss, 0) AS return_loss,
       COALESCE(s.avg_vehicle_count_sales, 0) AS avg_vehicle_sales,
       COALESCE(r.avg_vehicle_count_returns, 0) AS avg_vehicle_returns,
       (COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0)) AS net_impact,
       CASE WHEN (COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0)) >= 0 THEN 'Profit' ELSE 'Loss' END AS impact_category,
       DENSE_RANK() OVER (ORDER BY (COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0)) DESC) AS profit_rank
FROM date_dim d
LEFT JOIN daily_sales s ON s.d_date = d.d_date
LEFT JOIN daily_returns r ON r.d_date = d.d_date
WHERE d.d_year BETWEEN 2000 AND 2002
ORDER BY net_impact DESC
LIMIT 20
