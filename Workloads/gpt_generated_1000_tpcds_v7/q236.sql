SELECT
  cp.cp_department,
  cd_ref.cd_gender,
  SUM(cr.cr_net_loss) AS total_catalog_net_loss,
  SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_net_loss,
  SUM(ws.ws_net_profit) AS total_web_profit,
  (SUM(cr.cr_net_loss) + SUM(COALESCE(sr.sr_net_loss, 0)) + SUM(ws.ws_net_profit)) AS total_combined
FROM catalog_returns cr
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN customer c_ref
  ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer_demographics cd_ref
  ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN household_demographics hd_ref
  ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN customer c_ret
  ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
JOIN customer_demographics cd_ret
  ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN household_demographics hd_ret
  ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
LEFT JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN customer c_sr
  ON sr.sr_customer_sk = c_sr.c_customer_sk
LEFT JOIN customer_demographics cd_sr
  ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
LEFT JOIN household_demographics hd_sr
  ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN customer c_ws
  ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
JOIN customer_demographics cd_ws
  ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
JOIN household_demographics hd_ws
  ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
GROUP BY
  cp.cp_department,
  cd_ref.cd_gender
HAVING
  (SUM(cr.cr_net_loss) + SUM(COALESCE(sr.sr_net_loss, 0)) + SUM(ws.ws_net_profit)) > 1000
ORDER BY total_combined DESC
LIMIT 100
