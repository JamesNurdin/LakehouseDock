WITH catalog_agg AS (
   SELECT d.d_date AS sale_date,
          'catalog' AS channel,
          SUM(cs.cs_ext_sales_price) AS total_sales,
          SUM(cs.cs_net_profit) AS total_profit,
          CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'profitable' ELSE 'loss' END AS profit_flag
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE d.d_year = 2001
     AND p.p_discount_active = 'Y'
   GROUP BY d.d_date
),
web_agg AS (
   SELECT d.d_date AS sale_date,
          'web' AS channel,
          SUM(ws.ws_ext_sales_price) AS total_sales,
          SUM(ws.ws_net_profit) AS total_profit,
          CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'profitable' ELSE 'loss' END AS profit_flag
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE d.d_year = 2001
     AND sm.sm_type = 'AIR'
   GROUP BY d.d_date
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY sale_date, channel
LIMIT 100
