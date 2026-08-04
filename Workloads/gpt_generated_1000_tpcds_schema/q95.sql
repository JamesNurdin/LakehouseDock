SELECT
  cc.cc_name,
  cp.cp_type,
  hd.hd_income_band_sk,
  COUNT(DISTINCT cr.cr_order_number) AS num_returns,
  SUM(cr.cr_return_amount) AS total_return_amount,
  AVG(ws.ws_ext_discount_amt) AS avg_discount,
  SUM(ws.ws_net_paid) AS total_sales_net_paid,
  MAX(ws.ws_net_profit) AS max_net_profit,
  MIN(cr.cr_return_ship_cost) AS min_return_ship_cost
FROM tpcds.call_center AS cc
JOIN tpcds.catalog_returns AS cr
  ON cc.cc_call_center_sk = cr.cr_call_center_sk
JOIN tpcds.catalog_page AS cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.household_demographics AS hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.web_sales AS ws
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE cc.cc_mkt_class LIKE '%particles%'
  AND cc.cc_mkt_id IN (3, 5)
  AND cp.cp_type = 'Online'
  AND cp.cp_end_date_sk BETWEEN 2450900 AND 2451200
  AND ws.ws_ext_discount_amt > 500
GROUP BY cc.cc_name, cp.cp_type, hd.hd_income_band_sk
HAVING SUM(cr.cr_return_amount) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
