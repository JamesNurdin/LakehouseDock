SELECT
  cd.cd_gender,
  cc.cc_name,
  cp.cp_department,
  p.p_promo_name,
  r.r_reason_desc,
  SUM(cs.cs_net_profit) AS total_catalog_profit,
  SUM(ws.ws_net_profit) AS total_web_profit,
  SUM(sr.sr_return_amt) AS total_store_return_amount,
  COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
  AVG(sr.sr_refunded_cash) AS avg_refunded_cash
FROM tpcds.customer_demographics cd
JOIN tpcds.catalog_sales cs
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN tpcds.catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
JOIN tpcds.reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN tpcds.store_returns sr
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
  AND sr.sr_reason_sk = r.r_reason_sk
JOIN tpcds.web_sales ws
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  AND ws.ws_promo_sk = p.p_promo_sk
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE cc.cc_state = 'CA'
  AND cp.cp_type = 'A'
  AND p.p_discount_active = 'Y'
  AND sr.sr_refunded_cash > 100.00
GROUP BY
  cd.cd_gender,
  cc.cc_name,
  cp.cp_department,
  p.p_promo_name,
  r.r_reason_desc
