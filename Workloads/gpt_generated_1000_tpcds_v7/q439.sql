/*
Goal: Summarize catalog sales performance for the 'James Mcdonald' market manager, focusing on monthly catalog pages and high coupon amounts. The query aggregates sales, discounts, order counts, and profit by call center and catalog page, then returns the top 100 rows by total sales.
*/
SELECT
  cc.cc_name AS call_center_name,
  cp.cp_type,
  cp.cp_catalog_number,
  COUNT(DISTINCT cs.cs_order_number) AS order_count,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  AVG(cs.cs_ext_discount_amt) AS avg_discount,
  SUM(cs.cs_net_profit) AS total_profit,
  MIN(cs.cs_net_paid_inc_ship_tax) AS min_paid_inc_ship_tax,
  MAX(cs.cs_net_paid_inc_ship_tax) AS max_paid_inc_ship_tax
FROM
  tpcds.catalog_sales cs
  INNER JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  INNER JOIN tpcds.catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE
  cc.cc_market_manager = 'James Mcdonald'
  AND cp.cp_type = 'monthly'
  AND cs.cs_coupon_amt > 500
  AND cs.cs_net_paid_inc_ship_tax > 1000
GROUP BY
  cc.cc_name,
  cp.cp_type,
  cp.cp_catalog_number
ORDER BY
  total_sales DESC
LIMIT 100
