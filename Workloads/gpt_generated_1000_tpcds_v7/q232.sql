SELECT
  t.t_hour,
  cc.cc_state,
  cp.cp_catalog_number,
  p.p_promo_name,
  SUM(ss.ss_ext_sales_price) AS total_sales,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(wr.wr_return_amt) AS total_web_return,
  COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
  AVG(ss.ss_coupon_amt) AS avg_coupon,
  MIN(ss.ss_ext_sales_price) AS min_sale,
  MAX(ss.ss_ext_sales_price) AS max_sale
FROM tpcds.store_sales ss
JOIN tpcds.time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN tpcds.customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN tpcds.customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN tpcds.customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN tpcds.catalog_returns cr
  ON cr.cr_returned_time_sk = t.t_time_sk
JOIN tpcds.call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN tpcds.web_returns wr
  ON wr.wr_returned_time_sk = t.t_time_sk
JOIN tpcds.web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
  t.t_hour = 15
  AND cp.cp_catalog_number = 5
  AND cc.cc_state = 'CA'
GROUP BY
  t.t_hour,
  cc.cc_state,
  cp.cp_catalog_number,
  p.p_promo_name
ORDER BY
  total_sales DESC
LIMIT 100
