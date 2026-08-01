SELECT
  s.s_store_name,
  cc.cc_name,
  cd_bill.cd_education_status,
  SUM(cs.cs_net_paid) AS total_net_paid,
  SUM(cs.cs_net_profit) AS total_net_profit,
  SUM(sr.sr_net_loss) AS total_store_returns_loss,
  SUM(cr.cr_net_loss) AS total_catalog_returns_loss,
  SUM(wr.wr_net_loss) AS total_web_returns_loss,
  SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory_qty,
  CASE
    WHEN SUM(cs.cs_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) - COALESCE(SUM(cr.cr_net_loss), 0) - COALESCE(SUM(wr.wr_net_loss), 0) > 0
      THEN 'Profit'
    ELSE 'Loss'
  END AS profit_indicator
FROM catalog_sales cs
INNER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
INNER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
INNER JOIN time_dim td_sold ON cs.cs_sold_time_sk = td_sold.t_time_sk
INNER JOIN customer cu_bill ON cs.cs_bill_customer_sk = cu_bill.c_customer_sk
INNER JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
INNER JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN time_dim td_return ON cr.cr_returned_time_sk = td_return.t_time_sk
LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN customer cu_refunded ON cr.cr_refunded_customer_sk = cu_refunded.c_customer_sk
LEFT JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
LEFT JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
LEFT JOIN store_returns sr ON sr.sr_customer_sk = cu_bill.c_customer_sk
LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
LEFT JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
LEFT JOIN web_returns wr ON wr.wr_refunded_customer_sk = cu_bill.c_customer_sk
LEFT JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN customer_demographics cd_wr ON wr.wr_refunded_cdemo_sk = cd_wr.cd_demo_sk
LEFT JOIN household_demographics hd_wr ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
LEFT JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
FULL OUTER JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
GROUP BY GROUPING SETS (
  (s.s_store_name, cc.cc_name, cd_bill.cd_education_status),
  (s.s_store_name, cc.cc_name),
  (cc.cc_name, cd_bill.cd_education_status),
  (s.s_store_name),
  (cc.cc_name),
  (cd_bill.cd_education_status),
  ()
)
HAVING SUM(cs.cs_net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
