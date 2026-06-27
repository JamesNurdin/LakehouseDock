WITH
  store AS (
    SELECT
      ib.ib_lower_bound AS lower_bound,
      ib.ib_upper_bound AS upper_bound,
      'store' AS channel,
      ss.ss_net_paid_inc_tax AS net_paid,
      COALESCE(sr.sr_return_amt, 0) AS return_amt,
      ss.ss_customer_sk AS cust_sk
    FROM store_sales ss
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
      AND ss.ss_item_sk = sr.sr_item_sk
  ),
  catalog AS (
    SELECT
      ib.ib_lower_bound AS lower_bound,
      ib.ib_upper_bound AS upper_bound,
      'catalog' AS channel,
      cs.cs_net_paid_inc_tax AS net_paid,
      COALESCE(cr.cr_return_amount, 0) AS return_amt,
      cs.cs_bill_customer_sk AS cust_sk
    FROM catalog_sales cs
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
      AND cs.cs_item_sk = cr.cr_item_sk
  ),
  web AS (
    SELECT
      ib.ib_lower_bound AS lower_bound,
      ib.ib_upper_bound AS upper_bound,
      'web' AS channel,
      ws.ws_net_paid_inc_tax AS net_paid,
      COALESCE(wr.wr_return_amt, 0) AS return_amt,
      ws.ws_bill_customer_sk AS cust_sk
    FROM web_sales ws
    JOIN household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_returns wr
      ON ws.ws_order_number = wr.wr_order_number
      AND ws.ws_item_sk = wr.wr_item_sk
  )
SELECT
  lower_bound,
  upper_bound,
  channel,
  SUM(net_paid) AS total_net_paid_inc_tax,
  SUM(return_amt) AS total_return_amount,
  COUNT(DISTINCT cust_sk) AS distinct_customers,
  CASE WHEN SUM(net_paid) = 0 THEN 0
       ELSE SUM(return_amt) / SUM(net_paid)
  END AS return_rate
FROM (
  SELECT lower_bound, upper_bound, channel, net_paid, return_amt, cust_sk FROM store
  UNION ALL
  SELECT lower_bound, upper_bound, channel, net_paid, return_amt, cust_sk FROM catalog
  UNION ALL
  SELECT lower_bound, upper_bound, channel, net_paid, return_amt, cust_sk FROM web
) s
GROUP BY lower_bound, upper_bound, channel
ORDER BY lower_bound, upper_bound, channel
