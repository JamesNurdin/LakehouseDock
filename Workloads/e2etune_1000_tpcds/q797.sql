SELECT
  cc.cc_name AS call_center_name,
  cd.cd_gender,
  cd.cd_marital_status,
  SUM(ss.ss_net_profit) AS total_sales_profit,
  SUM(sr.sr_return_amt) AS total_store_returns,
  SUM(cr.cr_net_loss) AS total_catalog_returns_loss,
  (SUM(ss.ss_net_profit) - SUM(sr.sr_return_amt) - SUM(cr.cr_net_loss)) AS net_profit_adjusted
FROM store_sales ss
JOIN store_returns sr
  ON ss.ss_item_sk = sr.sr_item_sk
  AND ss.ss_ticket_number = sr.sr_ticket_number
JOIN customer_demographics cd
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN catalog_returns cr
  ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_division_name = 'pri'
  AND cc.cc_gmt_offset = -5.00
  AND cc.cc_open_date_sk = 2450952
  AND ss.ss_sold_date_sk BETWEEN 2450952 AND 2451063
GROUP BY
  cc.cc_name,
  cd.cd_gender,
  cd.cd_marital_status
ORDER BY net_profit_adjusted DESC
LIMIT 10
