WITH agg AS (
  SELECT
    w.w_warehouse_name,
    td.t_hour,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_returns
  FROM catalog_sales cs
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN store_returns sr
    ON cs.cs_item_sk = sr.sr_item_sk
    AND cs.cs_sold_date_sk = sr.sr_returned_date_sk
  GROUP BY w.w_warehouse_name, td.t_hour
)
SELECT
  w_warehouse_name,
  t_hour,
  total_sales,
  total_returns,
  total_sales - total_returns AS net_profit,
  CASE WHEN total_sales - total_returns > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
  RANK() OVER (PARTITION BY t_hour ORDER BY total_sales - total_returns DESC) AS profit_rank
FROM agg
ORDER BY t_hour, profit_rank
