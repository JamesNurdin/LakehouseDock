SELECT
  d.d_date,
  sm.sm_code,
  r.r_reason_desc,
  cc.cc_name,
  SUM(ss.ss_net_paid) AS total_sales,
  SUM(cr.cr_return_amount) AS total_catalog_return,
  SUM(wr.wr_return_amt) AS total_web_return,
  COUNT(*) AS transaction_count
FROM tpcds.date_dim d
JOIN tpcds.store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN tpcds.time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN tpcds.household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.catalog_returns cr
  ON cr.cr_returned_date_sk = d.d_date_sk
  AND cr.cr_returned_time_sk = t.t_time_sk
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
  ON wr.wr_returned_date_sk = d.d_date_sk
  AND wr.wr_returned_time_sk = t.t_time_sk
JOIN tpcds.reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN tpcds.web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_moy = 6
  AND sm.sm_carrier = 'DHL'
  AND t.t_minute = 15
GROUP BY d.d_date, sm.sm_code, r.r_reason_desc, cc.cc_name
ORDER BY total_sales DESC
LIMIT 100
