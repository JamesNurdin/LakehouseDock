SELECT
  i.i_item_id,
  i.i_brand,
  i.i_category,
  td_sold.t_hour,
  sm.sm_type,
  hd_bill.hd_buy_potential,
  cd_bill.cd_gender,
  wp.wp_url,
  COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
  SUM(cs.cs_net_paid) AS total_sales,
  SUM(cr.cr_return_amount) AS total_catalog_return,
  SUM(sr.sr_return_amt) AS total_store_return,
  SUM(wr.wr_return_amt) AS total_web_return,
  AVG(cs.cs_net_profit) AS avg_profit,
  MIN(i.i_current_price) AS min_price,
  MAX(i.i_current_price) AS max_price
FROM catalog_sales cs
JOIN time_dim td_sold
  ON cs.cs_sold_time_sk = td_sold.t_time_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
JOIN time_dim td_cr_ret
  ON cr.cr_returned_time_sk = td_cr_ret.t_time_sk
JOIN reason r_cr
  ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN store_sales ss
  ON ss.ss_item_sk = i.i_item_sk
     AND ss.ss_sold_time_sk = td_sold.t_time_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = ss.ss_item_sk
JOIN time_dim td_sr_ret
  ON sr.sr_return_time_sk = td_sr_ret.t_time_sk
JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
JOIN time_dim td_wr_ret
  ON wr.wr_returned_time_sk = td_wr_ret.t_time_sk
LEFT JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN income_band ib
  ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
WHERE i.i_current_price BETWEEN 20 AND 100
  AND i.i_brand = 'Brand#21'
  AND hd_bill.hd_buy_potential = '5001-10000'
  AND cd_bill.cd_gender = 'F'
  AND sm.sm_type = 'AIR'
  AND td_sold.t_hour BETWEEN 9 AND 17
  AND ib.ib_lower_bound >= 50000
GROUP BY
  i.i_item_id,
  i.i_brand,
  i.i_category,
  td_sold.t_hour,
  sm.sm_type,
  hd_bill.hd_buy_potential,
  cd_bill.cd_gender,
  wp.wp_url
LIMIT 100
