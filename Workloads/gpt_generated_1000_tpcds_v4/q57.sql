SELECT
  i.i_brand,
  i.i_category,
  ib.ib_income_band_sk,
  ib.ib_upper_bound,
  SUM(ss.ss_ext_sales_price) AS total_sales,
  SUM(COALESCE(sr.sr_return_amt, 0)) AS total_returns,
  SUM(ss.ss_net_profit) AS total_profit,
  COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
FROM tpcds.store_sales ss
JOIN tpcds.item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN tpcds.household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN tpcds.store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
  AND sr.sr_item_sk = ss.ss_item_sk
WHERE ss.ss_sold_time_sk IN (35137, 47818, 65476)
  AND i.i_current_price > 50
  AND hd.hd_vehicle_count >= 2
GROUP BY
  i.i_brand,
  i.i_category,
  ib.ib_income_band_sk,
  ib.ib_upper_bound
ORDER BY total_sales DESC
LIMIT 100
