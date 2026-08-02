SELECT
  s.s_store_name,
  i1.i_category,
  SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS store_sales_ext,
  SUM(COALESCE(cs.cs_ext_sales_price, 0)) AS catalog_sales_ext,
  SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS web_sales_ext,
  SUM(COALESCE(sr.sr_return_amt, 0)) AS store_return_amt,
  SUM(COALESCE(cr.cr_return_amount, 0)) AS catalog_return_amt,
  COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
  CASE WHEN SUM(COALESCE(ss.ss_ext_sales_price, 0)) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
FROM store_sales ss
FULL OUTER JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN item i1 ON ss.ss_item_sk = i1.i_item_sk
LEFT JOIN customer_demographics cd1 ON ss.ss_cdemo_sk = cd1.cd_demo_sk
LEFT JOIN household_demographics hd1 ON ss.ss_hdemo_sk = hd1.hd_demo_sk
LEFT JOIN income_band ib ON hd1.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN customer_address ca1 ON ss.ss_addr_sk = ca1.ca_address_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN reason r1 ON sr.sr_reason_sk = r1.r_reason_sk
LEFT JOIN item i2 ON sr.sr_item_sk = i2.i_item_sk
LEFT JOIN catalog_sales cs ON cs.cs_item_sk = i1.i_item_sk
LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN reason r2 ON cr.cr_reason_sk = r2.r_reason_sk
LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN ship_mode sm1 ON cs.cs_ship_mode_sk = sm1.sm_ship_mode_sk
LEFT JOIN web_sales ws ON ws.ws_item_sk = i1.i_item_sk
LEFT JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
LEFT JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
GROUP BY GROUPING SETS (
  (s.s_store_name, i1.i_category),
  (s.s_store_name),
  (i1.i_category),
  ()
)
ORDER BY profit_flag DESC, store_sales_ext DESC
LIMIT 100
