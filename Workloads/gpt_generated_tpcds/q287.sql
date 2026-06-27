WITH channel_data AS (
  SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ss.ss_net_profit AS net_profit,
    COALESCE(sr.sr_net_loss, 0.0) AS net_loss,
    ss.ss_net_paid AS net_paid
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
  WHERE ss.ss_sold_date_sk >= 2451010

  UNION ALL

  SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cs.cs_net_profit AS net_profit,
    COALESCE(cr.cr_net_loss, 0.0) AS net_loss,
    cs.cs_net_paid AS net_paid
  FROM catalog_sales cs
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN catalog_returns cr ON cr.cr_item_sk = cs.cs_item_sk AND cr.cr_order_number = cs.cs_order_number
  WHERE cs.cs_sold_date_sk >= 2451010

  UNION ALL

  SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ws.ws_net_profit AS net_profit,
    COALESCE(wr.wr_net_loss, 0.0) AS net_loss,
    ws.ws_net_paid AS net_paid
  FROM web_sales ws
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
  WHERE ws.ws_sold_date_sk >= 2451010
)
SELECT
  ib_income_band_sk,
  ib_lower_bound,
  ib_upper_bound,
  SUM(net_profit) AS total_net_profit,
  SUM(net_loss)   AS total_net_loss,
  SUM(net_paid)   AS total_net_paid,
  COUNT(*)        AS transaction_count
FROM channel_data
GROUP BY ib_income_band_sk, ib_lower_bound, ib_upper_bound
ORDER BY ib_income_band_sk
