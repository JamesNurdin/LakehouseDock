WITH
  rr AS (
    SELECT
      sr_reason_sk,
      sr_hdemo_sk,
      SUM(sr_refunded_cash) AS total_refunded,
      COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_refunded_cash > 50
      AND sr_reversed_charge < 100
    GROUP BY sr_reason_sk, sr_hdemo_sk
  ),
  cs AS (
    SELECT
      cs_call_center_sk,
      cs_bill_hdemo_sk,
      SUM(cs_net_profit) AS total_cs_profit,
      COUNT(DISTINCT cs_order_number) AS distinct_orders
    FROM catalog_sales
    WHERE cs_quantity > 5
      AND cs_net_profit > 0
    GROUP BY cs_call_center_sk, cs_bill_hdemo_sk
  )
SELECT
  cc.cc_state,
  ca.ca_state,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  r.r_reason_desc,
  SUM(ss.ss_net_profit) AS store_sales_profit,
  SUM(cs.total_cs_profit) AS catalog_sales_profit,
  SUM(rr.total_refunded) AS total_refunded_cash,
  COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
  CASE
    WHEN SUM(ss.ss_net_profit) > 10000 THEN 'HighProfit'
    ELSE 'LowProfit'
  END AS profit_category
FROM rr
JOIN reason r
  ON rr.sr_reason_sk = r.r_reason_sk
JOIN household_demographics hd
  ON rr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_sales ss
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN cs
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_state = 'CA'
  AND ca.ca_state = 'TX'
  AND ib.ib_lower_bound >= 50000
  AND r.r_reason_desc LIKE '%size%'
GROUP BY
  cc.cc_state,
  ca.ca_state,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  r.r_reason_desc
ORDER BY store_sales_profit DESC
LIMIT 100
