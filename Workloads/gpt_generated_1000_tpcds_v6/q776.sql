SELECT
  cc.cc_name,
  sm.sm_code,
  cd.cd_gender,
  SUM(cs.cs_net_profit) AS total_catalog_profit,
  SUM(ws.ws_net_profit) AS total_web_profit,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(sr.sr_store_credit) AS total_store_credit,
  RANK() OVER (PARTITION BY cc.cc_name ORDER BY SUM(cs.cs_net_profit) DESC) AS catalog_profit_rank
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
JOIN store_returns sr
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN web_sales ws
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE cc.cc_rec_start_date >= DATE '2001-01-01'
  AND cc.cc_rec_end_date <= DATE '2002-12-31'
  AND sm.sm_code = 'AIR'
  AND cd.cd_gender = 'F'
  AND cs.cs_net_paid > 5000
  AND ws.ws_ext_tax > 20
  AND EXISTS (
    SELECT 1
    FROM web_sales ws2
    WHERE ws2.ws_bill_cdemo_sk = cd.cd_demo_sk
      AND ws2.ws_sold_date_sk = cs.cs_sold_date_sk
      AND ws2.ws_ext_tax > 30
  )
GROUP BY cc.cc_name, sm.sm_code, cd.cd_gender
ORDER BY total_catalog_profit DESC
LIMIT 100
