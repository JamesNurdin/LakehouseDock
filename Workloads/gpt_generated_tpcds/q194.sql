WITH store_sales_joined AS (
   SELECT
      ss.ss_ticket_number      AS order_key,
      ss.ss_promo_sk           AS promo_sk,
      ss.ss_net_profit         AS net_profit,
      COALESCE(sr.sr_net_loss, 0) AS net_loss,
      ss.ss_customer_sk        AS customer_sk,
      ss.ss_hdemo_sk           AS hdemo_sk
   FROM store_sales ss
   LEFT JOIN store_returns sr
     ON ss.ss_ticket_number = sr.sr_ticket_number
),
catalog_sales_joined AS (
   SELECT
      cs.cs_order_number       AS order_key,
      cs.cs_promo_sk           AS promo_sk,
      cs.cs_net_profit         AS net_profit,
      COALESCE(cr.cr_net_loss, 0) AS net_loss,
      cs.cs_bill_customer_sk   AS customer_sk,
      cs.cs_bill_hdemo_sk      AS hdemo_sk
   FROM catalog_sales cs
   LEFT JOIN catalog_returns cr
     ON cs.cs_order_number = cr.cr_order_number
),
web_sales_joined AS (
   SELECT
      ws.ws_order_number       AS order_key,
      ws.ws_promo_sk           AS promo_sk,
      ws.ws_net_profit         AS net_profit,
      COALESCE(wr.wr_net_loss, 0) AS net_loss,
      ws.ws_bill_customer_sk   AS customer_sk,
      ws.ws_bill_hdemo_sk      AS hdemo_sk
   FROM web_sales ws
   LEFT JOIN web_returns wr
     ON ws.ws_order_number = wr.wr_order_number
),
sales_all AS (
   SELECT * FROM store_sales_joined
   UNION ALL
   SELECT * FROM catalog_sales_joined
   UNION ALL
   SELECT * FROM web_sales_joined
)
SELECT
   p.p_promo_id,
   ib.ib_lower_bound,
   ib.ib_upper_bound,
   SUM(s.net_profit)                     AS total_net_profit,
   SUM(s.net_loss)                       AS total_net_loss,
   SUM(s.net_profit) - SUM(s.net_loss)   AS net_contribution,
   COUNT(*)                              AS transaction_count
FROM sales_all s
JOIN promotion p
  ON s.promo_sk = p.p_promo_sk
JOIN household_demographics hd
  ON s.hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE s.promo_sk IS NOT NULL
GROUP BY
   p.p_promo_id,
   ib.ib_lower_bound,
   ib.ib_upper_bound
ORDER BY net_contribution DESC
LIMIT 100
