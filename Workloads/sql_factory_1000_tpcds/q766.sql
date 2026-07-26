WITH cs_agg AS (
   SELECT cs_bill_customer_sk AS customer_sk,
          SUM(cs_net_profit) AS cs_total_profit,
          SUM(cs_ext_discount_amt) AS cs_total_discount,
          COUNT(*) AS cs_order_count
   FROM catalog_sales
   GROUP BY cs_bill_customer_sk
),
ws_agg AS (
   SELECT ws_bill_customer_sk AS customer_sk,
          SUM(ws_net_profit) AS ws_total_profit,
          SUM(ws_ext_discount_amt) AS ws_total_discount,
          COUNT(*) AS ws_order_count
   FROM web_sales
   GROUP BY ws_bill_customer_sk
),
sr_agg AS (
   SELECT sr_customer_sk AS customer_sk,
          SUM(sr_net_loss) AS sr_total_loss,
          SUM(sr_return_amt) AS sr_total_return,
          COUNT(*) AS sr_return_count
   FROM store_returns
   GROUP BY sr_customer_sk
)
SELECT
   c.c_customer_id,
   COALESCE(cs.cs_total_profit, 0) + COALESCE(ws.ws_total_profit, 0) - COALESCE(sr.sr_total_loss, 0) AS net_profit,
   COALESCE(cs.cs_total_discount, 0) + COALESCE(ws.ws_total_discount, 0) AS total_discount,
   COALESCE(cs.cs_order_count, 0) + COALESCE(ws.ws_order_count, 0) AS total_orders,
   CASE
      WHEN COALESCE(cs.cs_total_profit, 0) + COALESCE(ws.ws_total_profit, 0) - COALESCE(sr.sr_total_loss, 0) > 10000 THEN 'High'
      WHEN COALESCE(cs.cs_total_profit, 0) + COALESCE(ws.ws_total_profit, 0) - COALESCE(sr.sr_total_loss, 0) BETWEEN 5000 AND 10000 THEN 'Medium'
      ELSE 'Low'
   END AS profit_category,
   RANK() OVER (
      ORDER BY COALESCE(cs.cs_total_profit, 0) + COALESCE(ws.ws_total_profit, 0) - COALESCE(sr.sr_total_loss, 0) DESC
   ) AS profit_rank
FROM customer c
LEFT JOIN cs_agg cs ON c.c_customer_sk = cs.customer_sk
LEFT JOIN ws_agg ws ON c.c_customer_sk = ws.customer_sk
LEFT JOIN sr_agg sr ON c.c_customer_sk = sr.customer_sk
WHERE COALESCE(cs.cs_total_profit, 0) + COALESCE(ws.ws_total_profit, 0) - COALESCE(sr.sr_total_loss, 0) > 0
ORDER BY net_profit DESC
LIMIT 20
