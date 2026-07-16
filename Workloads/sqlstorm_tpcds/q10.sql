WITH store_agg AS (
  SELECT ss.ss_promo_sk,
         SUM(ss.ss_net_paid) AS store_sales,
         SUM(ss.ss_net_profit) AS store_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY ss.ss_promo_sk
),
catalog_agg AS (
  SELECT cs.cs_promo_sk,
         SUM(cs.cs_net_paid) AS catalog_sales,
         SUM(cs.cs_net_profit) AS catalog_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY cs.cs_promo_sk
),
web_agg AS (
  SELECT ws.ws_promo_sk,
         SUM(ws.ws_net_paid) AS web_sales,
         SUM(ws.ws_net_profit) AS web_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY ws.ws_promo_sk
)
SELECT p.p_promo_id,
       p.p_promo_name,
       COALESCE(sa.store_sales, 0) AS store_sales,
       COALESCE(ca.catalog_sales, 0) AS catalog_sales,
       COALESCE(wa.web_sales, 0) AS web_sales,
       COALESCE(sa.store_sales, 0) + COALESCE(ca.catalog_sales, 0) + COALESCE(wa.web_sales, 0) AS total_sales,
       COALESCE(sa.store_profit, 0) AS store_profit,
       COALESCE(ca.catalog_profit, 0) AS catalog_profit,
       COALESCE(wa.web_profit, 0) AS web_profit,
       COALESCE(sa.store_profit, 0) + COALESCE(ca.catalog_profit, 0) + COALESCE(wa.web_profit, 0) AS total_profit
FROM promotion p
LEFT JOIN store_agg sa ON p.p_promo_sk = sa.ss_promo_sk
LEFT JOIN catalog_agg ca ON p.p_promo_sk = ca.cs_promo_sk
LEFT JOIN web_agg wa ON p.p_promo_sk = wa.ws_promo_sk
WHERE COALESCE(sa.store_sales, 0) + COALESCE(ca.catalog_sales, 0) + COALESCE(wa.web_sales, 0) > 1000000
ORDER BY total_sales DESC
LIMIT 10
