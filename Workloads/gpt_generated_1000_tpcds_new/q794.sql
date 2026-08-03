WITH union_data AS (
  SELECT
    cp.cp_department AS department,
    cp.cp_catalog_page_number AS page_number,
    CASE WHEN hd.hd_vehicle_count > 2 THEN 'HighVehicle' ELSE 'LowVehicle' END AS vehicle_category,
    SUM(cs.cs_net_profit) AS sales_profit,
    0.0 AS return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS sales_orders,
    0 AS return_cnt
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  WHERE cs.cs_wholesale_cost > 10
    AND cs.cs_ext_list_price BETWEEN 1000 AND 15000
    AND w.w_city = 'Seattle'
    AND t.t_hour BETWEEN 9 AND 19
    AND hd.hd_vehicle_count >= 2
    AND cp.cp_type = 'Regular'
  GROUP BY cp.cp_department, cp.cp_catalog_page_number, hd.hd_vehicle_count
  HAVING SUM(cs.cs_net_profit) > 1000

  UNION DISTINCT

  SELECT
    cp.cp_department AS department,
    cp.cp_catalog_page_number AS page_number,
    CASE WHEN hd.hd_vehicle_count > 2 THEN 'HighVehicle' ELSE 'LowVehicle' END AS vehicle_category,
    0.0 AS sales_profit,
    SUM(sr.sr_refunded_cash) AS return_amount,
    0 AS sales_orders,
    COUNT(*) AS return_cnt
  FROM store_returns sr
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  JOIN catalog_sales cs ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  WHERE sr.sr_refunded_cash > 100
    AND sr.sr_return_tax > 1
    AND w.w_city = 'Seattle'
    AND t.t_hour BETWEEN 9 AND 19
    AND hd.hd_vehicle_count >= 2
    AND cp.cp_type = 'Regular'
  GROUP BY cp.cp_department, cp.cp_catalog_page_number, hd.hd_vehicle_count
  HAVING SUM(sr.sr_refunded_cash) > 200
)
SELECT
  department,
  page_number,
  vehicle_category,
  SUM(sales_profit) AS total_sales_profit,
  SUM(return_amount) AS total_return_amount,
  SUM(sales_orders) AS total_sales_orders,
  SUM(return_cnt) AS total_return_cnt,
  (SUM(sales_profit) - SUM(return_amount)) AS net_metric,
  RANK() OVER (PARTITION BY department ORDER BY (SUM(sales_profit) - SUM(return_amount)) DESC) AS dept_rank
FROM union_data
GROUP BY department, page_number, vehicle_category
HAVING SUM(sales_profit) > 2000
   AND SUM(return_amount) < 5000
   AND COUNT(*) >= 1
ORDER BY department, dept_rank
LIMIT 100
