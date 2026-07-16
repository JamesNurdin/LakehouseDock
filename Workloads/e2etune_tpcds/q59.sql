WITH catalog_agg AS (
    SELECT cs.cs_promo_sk AS promo_sk,
           SUM(cs.cs_ext_sales_price) AS catalog_sales,
           SUM(cs.cs_net_profit) AS catalog_net_profit,
           COUNT(*) AS catalog_orders
    FROM catalog_sales cs
    WHERE cs.cs_wholesale_cost > 50
      AND cs.cs_ext_tax > 20
    GROUP BY cs.cs_promo_sk
),
web_agg AS (
    SELECT ws.ws_promo_sk AS promo_sk,
           SUM(ws.ws_ext_sales_price) AS web_sales,
           SUM(ws.ws_net_profit) AS web_net_profit,
           COUNT(*) AS web_orders
    FROM web_sales ws
    WHERE ws.ws_wholesale_cost > 50
      AND ws.ws_ext_tax > 20
    GROUP BY ws.ws_promo_sk
)
SELECT p.p_promo_id,
       p.p_promo_name,
       COALESCE(ca.catalog_sales, 0) AS catalog_sales,
       COALESCE(wa.web_sales, 0) AS web_sales,
       COALESCE(ca.catalog_net_profit, 0) AS catalog_net_profit,
       COALESCE(wa.web_net_profit, 0) AS web_net_profit,
       (COALESCE(ca.catalog_sales, 0) + COALESCE(wa.web_sales, 0)) AS total_sales,
       (COALESCE(ca.catalog_net_profit, 0) + COALESCE(wa.web_net_profit, 0)) AS total_net_profit,
       CASE 
           WHEN (COALESCE(ca.catalog_sales, 0) + COALESCE(wa.web_sales, 0)) = 0 THEN 0
           ELSE (COALESCE(ca.catalog_net_profit, 0) + COALESCE(wa.web_net_profit, 0)) /
                (COALESCE(ca.catalog_sales, 0) + COALESCE(wa.web_sales, 0))
       END AS profit_margin,
       RANK() OVER (ORDER BY (COALESCE(ca.catalog_net_profit, 0) + COALESCE(wa.web_net_profit, 0)) DESC) AS profit_rank
FROM promotion p
LEFT JOIN catalog_agg ca ON p.p_promo_sk = ca.promo_sk
LEFT JOIN web_agg wa ON p.p_promo_sk = wa.promo_sk
WHERE p.p_discount_active = 'Y'
  AND (COALESCE(ca.catalog_sales, 0) + COALESCE(wa.web_sales, 0)) > 10000
ORDER BY total_net_profit DESC
LIMIT 20
