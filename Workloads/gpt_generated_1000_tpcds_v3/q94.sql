SELECT
  d_sales.d_year,
  d_sales.d_month_seq,
  t_sold.t_hour,
  cc_date.cc_state,
  cp.cp_department,
  hd.hd_buy_potential,
  ib.ib_lower_bound,
  COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
  SUM(ss.ss_quantity) AS total_store_quantity,
  SUM(ss.ss_net_paid_inc_tax) AS total_store_net_paid,
  SUM(ss.ss_net_profit) AS total_store_profit,
  SUM(ss.ss_ext_discount_amt) AS total_store_discount,
  SUM(cs.cs_quantity) AS total_catalog_quantity,
  SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
  SUM(cs.cs_net_profit) AS total_catalog_profit,
  SUM(cs.cs_ext_discount_amt) AS total_catalog_discount,
  SUM(ws.ws_quantity) AS total_web_quantity,
  SUM(ws.ws_ext_sales_price) AS total_web_sales,
  SUM(ws.ws_net_profit) AS total_web_profit,
  SUM(ws.ws_ext_discount_amt) AS total_web_discount,
  SUM(sr.sr_return_quantity) AS total_store_returns,
  SUM(cr.cr_return_quantity) AS total_catalog_returns,
  SUM(wr.wr_return_quantity) AS total_web_returns,
  (SELECT AVG(cs2.cs_ext_discount_amt) FROM catalog_sales cs2) AS avg_catalog_discount,
  (SELECT AVG(ws2.ws_ext_discount_amt) FROM web_sales ws2) AS avg_web_discount
FROM store_sales ss
JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sold ON ss.ss_sold_time_sk = t_sold.t_time_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN call_center cc_date ON cc_date.cc_closed_date_sk = d_sales.d_date_sk
JOIN catalog_sales cs ON cs.cs_sold_date_sk = d_sales.d_date_sk
                     AND cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN call_center cc_sales ON cs.cs_call_center_sk = cc_sales.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d_sales.d_date_sk
                     AND sr.sr_return_time_sk = t_sold.t_time_sk
                     AND sr.sr_item_sk = ss.ss_item_sk
                     AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sales.d_date_sk
                         AND cr.cr_returned_time_sk = t_sold.t_time_sk
                         AND cr.cr_item_sk = cs.cs_item_sk
                         AND cr.cr_order_number = cs.cs_order_number
JOIN call_center cc_return ON cr.cr_call_center_sk = cc_return.cc_call_center_sk
JOIN catalog_page cp_return ON cr.cr_catalog_page_sk = cp_return.cp_catalog_page_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d_sales.d_date_sk
                     AND ws.ws_sold_time_sk = t_sold.t_time_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_sales.d_date_sk
                     AND wr.wr_returned_time_sk = t_sold.t_time_sk
                     AND wr.wr_item_sk = ws.ws_item_sk
                     AND wr.wr_order_number = ws.ws_order_number
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE d_sales.d_year = 2001
  AND d_sales.d_month_seq BETWEEN 1200 AND 1202
  AND t_sold.t_hour BETWEEN 9 AND 17
  AND cc_date.cc_state = 'CA'
  AND cp.cp_department = 'Sports'
  AND hd.hd_buy_potential = '1001-5000'
  AND ib.ib_lower_bound >= 50000
  AND cd.cd_gender = 'M'
  AND r_cr.r_reason_desc LIKE '%damaged%'
  AND ss.ss_quantity > 5
GROUP BY
  d_sales.d_year,
  d_sales.d_month_seq,
  t_sold.t_hour,
  cc_date.cc_state,
  cp.cp_department,
  hd.hd_buy_potential,
  ib.ib_lower_bound
ORDER BY total_store_net_paid DESC
LIMIT 100
