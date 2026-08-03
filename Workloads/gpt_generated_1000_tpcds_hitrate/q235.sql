WITH catalog_agg AS (
   SELECT
       'Catalog' AS channel,
       w.w_city,
       SUM(cs.cs_net_profit) AS net_profit
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_year = 2002
     AND w.w_city IN ('Riverside', 'Greenwood')
   GROUP BY w.w_city
),
web_agg AS (
   SELECT
       'Web' AS channel,
       w.w_city,
       SUM(ws.ws_net_profit) AS net_profit
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_year = 2002
     AND w.w_city IN ('Riverside', 'Greenwood')
   GROUP BY w.w_city
),
combined AS (
   SELECT channel, w_city, net_profit FROM catalog_agg
   UNION ALL
   SELECT channel, w_city, net_profit FROM web_agg
)
SELECT DISTINCT channel, w_city, net_profit
FROM combined
ORDER BY net_profit DESC
LIMIT 100
