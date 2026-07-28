WITH catalog_agg AS (
   SELECT
       'Catalog' AS sales_channel,
       sm.sm_code AS ship_mode_code,
       SUM(cs.cs_ext_sales_price) AS total_sales
   FROM tpcds.catalog_sales cs
   JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN tpcds.time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   WHERE sm.sm_code = 'AIR'
     AND cs.cs_quantity > 2
   GROUP BY sm.sm_code
),
web_agg AS (
   SELECT
       'Web' AS sales_channel,
       sm.sm_code AS ship_mode_code,
       SUM(ws.ws_ext_sales_price) AS total_sales
   FROM tpcds.web_sales ws
   JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN tpcds.time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   WHERE sm.sm_code = 'SEA'
     AND ws.ws_quantity > 2
   GROUP BY sm.sm_code
)
SELECT sales_channel, ship_mode_code, total_sales
FROM catalog_agg
UNION ALL
SELECT sales_channel, ship_mode_code, total_sales
FROM web_agg
ORDER BY total_sales DESC
LIMIT 100
