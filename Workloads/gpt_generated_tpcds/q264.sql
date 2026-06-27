WITH cs_agg AS (
   SELECT
      cs.cs_promo_sk,
      SUM(cs.cs_net_profit) AS total_catalog_profit,
      COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_catalog_customers
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY cs.cs_promo_sk
),
ws_agg AS (
   SELECT
      ws.ws_promo_sk,
      SUM(ws.ws_net_profit) AS total_web_profit,
      COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_web_customers
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY ws.ws_promo_sk
)
SELECT
   p.p_promo_id,
   p.p_promo_name,
   COALESCE(cs_agg.total_catalog_profit, 0) AS total_catalog_profit,
   COALESCE(ws_agg.total_web_profit, 0) AS total_web_profit,
   COALESCE(cs_agg.distinct_catalog_customers, 0) AS distinct_catalog_customers,
   COALESCE(ws_agg.distinct_web_customers, 0) AS distinct_web_customers,
   COALESCE(cs_agg.total_catalog_profit, 0) + COALESCE(ws_agg.total_web_profit, 0) AS total_profit
FROM promotion p
LEFT JOIN cs_agg ON p.p_promo_sk = cs_agg.cs_promo_sk
LEFT JOIN ws_agg ON p.p_promo_sk = ws_agg.ws_promo_sk
ORDER BY total_profit DESC
LIMIT 10
