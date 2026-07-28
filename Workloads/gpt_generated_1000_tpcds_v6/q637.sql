SELECT
  cc.cc_name AS call_center_name,
  sm.sm_code AS ship_mode_code,
  td.t_meal_time AS meal_time,
  cp.cp_department AS department,
  i.i_brand AS item_brand,
  hd_bill.hd_income_band_sk AS income_band,
  COUNT(DISTINCT cs.cs_order_number) AS order_count,
  SUM(cs.cs_net_paid) AS total_net_paid,
  SUM(cs.cs_net_profit) AS total_net_profit,
  AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
  SUM(cr.cr_return_amount) AS total_catalog_return_amount,
  SUM(wr.wr_return_amt) AS total_web_return_amount,
  MIN(cs.cs_sold_date_sk) AS min_sold_date_sk,
  MAX(cs.cs_sold_date_sk) AS max_sold_date_sk
FROM catalog_sales cs
JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                     AND cr.cr_item_sk = cs.cs_item_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
JOIN household_demographics hd_wr_refund ON wr.wr_refunded_hdemo_sk = hd_wr_refund.hd_demo_sk
JOIN household_demographics hd_wr_return ON wr.wr_returning_hdemo_sk = hd_wr_return.hd_demo_sk
WHERE cc.cc_state = 'CA'
  AND sm.sm_code = 'AIR'
  AND i.i_brand = 'BrandX'
  AND cp.cp_department = 'Sports'
  AND td.t_meal_time = 'dinner'
  AND hd_bill.hd_income_band_sk = 5
  AND cs.cs_quantity > 5
GROUP BY
  cc.cc_name,
  sm.sm_code,
  td.t_meal_time,
  cp.cp_department,
  i.i_brand,
  hd_bill.hd_income_band_sk
ORDER BY total_net_profit DESC
