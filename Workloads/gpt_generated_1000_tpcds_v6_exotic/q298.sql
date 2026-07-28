/*
Goal: Analyze catalog sales by department and household buying potential, summarizing sales amounts, tax, order counts, and high shipping‑cost occurrences while applying realistic filters across all five TPC‑DS tables.
*/
SELECT
  cp.cp_department,
  hd_bill.hd_buy_potential,
  SUM(CASE WHEN cs.cs_ext_ship_cost > 500 THEN 1 ELSE 0 END) AS high_ship_cost_cnt,
  SUM(cs.cs_ext_sales_price) AS total_sales_price,
  AVG(cs.cs_ext_tax) AS avg_tax,
  COUNT(*) AS order_cnt,
  MIN(cs.cs_net_paid) AS min_net_paid,
  MAX(cs.cs_net_paid) AS max_net_paid
FROM catalog_sales cs
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN time_dim td
  ON cs.cs_sold_time_sk = td.t_time_sk
JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib
  ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN household_demographics hd_ship
  ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
WHERE cp.cp_department = 'Electronics'
  AND cp.cp_type = 'Standard'
  AND cs.cs_ext_ship_cost > 300
  AND cs.cs_ext_ship_cost < 800
  AND cs.cs_net_paid_inc_ship_tax BETWEEN 500 AND 5000
  AND td.t_hour IN (9, 10, 11)
  AND hd_bill.hd_buy_potential = '5000-10000'
  AND ib.ib_lower_bound >= 10001
  AND ib.ib_upper_bound <= 50000
GROUP BY ROLLUP (cp.cp_department, hd_bill.hd_buy_potential)
ORDER BY total_sales_price DESC
LIMIT 100
