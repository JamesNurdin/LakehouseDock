WITH air_sales AS (
   SELECT
       sm.sm_ship_mode_id,
       sm.sm_code,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       AVG(ws.ws_net_profit) AS avg_net_profit,
       CASE WHEN SUM(ws.ws_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
   FROM tpcds.web_sales ws
   JOIN tpcds.ship_mode sm
     ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE sm.sm_code = 'AIR'
     AND ws.ws_ext_tax > 100
   GROUP BY sm.sm_ship_mode_id, sm.sm_code
),
sea_sales AS (
   SELECT
       sm.sm_ship_mode_id,
       sm.sm_code,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       AVG(ws.ws_net_profit) AS avg_net_profit,
       CASE WHEN SUM(ws.ws_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
   FROM tpcds.web_sales ws
   JOIN tpcds.ship_mode sm
     ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE sm.sm_code = 'SEA'
     AND ws.ws_ext_tax <= 100
   GROUP BY sm.sm_ship_mode_id, sm.sm_code
)
SELECT *
FROM air_sales
UNION ALL
SELECT *
FROM sea_sales
ORDER BY total_sales DESC
LIMIT 100
