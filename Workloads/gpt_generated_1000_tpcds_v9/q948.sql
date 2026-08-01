SELECT
  s.s_store_name,
  sm_cr.sm_type AS ship_mode_type,
  r_cr.r_reason_desc AS catalog_return_reason,
  ib_ref.ib_lower_bound,
  ib_ref.ib_upper_bound,
  SUM(cr.cr_return_amount) AS sum_catalog_return_amount,
  SUM(sr.sr_return_amt) AS sum_store_return_amount,
  SUM(wr.wr_return_amt) AS sum_web_return_amount,
  SUM(COALESCE(cr.cr_net_loss, 0) + COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_net_loss,
  CASE WHEN SUM(COALESCE(cr.cr_net_loss, 0) + COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
FROM tpcds.catalog_returns cr
JOIN tpcds.catalog_sales cs
  ON cr.cr_order_number = cs.cs_order_number
 AND cr.cr_item_sk = cs.cs_item_sk
JOIN tpcds.customer_demographics cd_ref
  ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN tpcds.household_demographics hd_ref
  ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN tpcds.income_band ib_ref
  ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
JOIN tpcds.customer_demographics cd_ret
  ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN tpcds.household_demographics hd_ret
  ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN tpcds.income_band ib_ret
  ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk
JOIN tpcds.reason r_cr
  ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN tpcds.ship_mode sm_cr
  ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN tpcds.customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN tpcds.household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN tpcds.income_band ib_bill
  ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
JOIN tpcds.customer_demographics cd_ship
  ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN tpcds.household_demographics hd_ship
  ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN tpcds.income_band ib_ship
  ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
JOIN tpcds.ship_mode sm_cs
  ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN tpcds.store_returns sr
  ON sr.sr_cdemo_sk = cd_ref.cd_demo_sk
 AND sr.sr_hdemo_sk = hd_ref.hd_demo_sk
JOIN tpcds.store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN tpcds.reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN tpcds.web_returns wr
  ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
 AND wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN tpcds.reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN tpcds.web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
GROUP BY GROUPING SETS (
    (s.s_store_name, sm_cr.sm_type, r_cr.r_reason_desc, ib_ref.ib_lower_bound, ib_ref.ib_upper_bound),
    (s.s_store_name, sm_cr.sm_type, r_cr.r_reason_desc),
    (s.s_store_name, sm_cr.sm_type),
    (s.s_store_name),
    ()
)
ORDER BY total_net_loss DESC, loss_category ASC
LIMIT 100
