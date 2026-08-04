WITH cs AS (
   SELECT d.d_year AS year,
          sm.sm_ship_mode_id AS ship_mode_id,
          SUM(cs.cs_ext_sales_price) AS total_sales,
          SUM(cs.cs_net_profit) AS total_profit,
          CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_category,
          'catalog' AS source
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE d.d_year = 2001
   GROUP BY d.d_year, sm.sm_ship_mode_id
   HAVING SUM(cs.cs_ext_sales_price) > 10000
),
ws AS (
   SELECT d.d_year AS year,
          sm.sm_ship_mode_id AS ship_mode_id,
          SUM(ws.ws_ext_sales_price) AS total_sales,
          SUM(ws.ws_net_profit) AS total_profit,
          CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_category,
          'web' AS source
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE d.d_year = 2001
   GROUP BY d.d_year, sm.sm_ship_mode_id
   HAVING SUM(ws.ws_ext_sales_price) > 10000
)
SELECT *
FROM cs
UNION ALL
SELECT *
FROM ws
ORDER BY year DESC, ship_mode_id
LIMIT 100
