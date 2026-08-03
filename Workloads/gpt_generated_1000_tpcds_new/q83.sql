SELECT
  ss.ss_store_sk,
  SUM(ss.ss_ext_sales_price) AS total_sales,
  SUM(sr.sr_refunded_cash) AS total_refunded,
  SUM(ss.ss_net_profit) AS total_profit
FROM tpcds.store_sales ss
JOIN tpcds.store_returns sr
  ON ss.ss_item_sk = sr.sr_item_sk
  AND ss.ss_ticket_number = sr.sr_ticket_number
WHERE ss.ss_store_sk = 925
  AND sr.sr_fee > 30
GROUP BY ss.ss_store_sk
ORDER BY total_sales DESC
