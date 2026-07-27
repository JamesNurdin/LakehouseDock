WITH catalog_agg AS (
       SELECT sm.sm_ship_mode_id AS ship_mode_id,
              SUM(cs.cs_ext_sales_price) AS total_sales,
              'catalog' AS channel
       FROM catalog_sales cs
       JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
       JOIN time_dim td   ON cs.cs_sold_time_sk = td.t_time_sk
       WHERE td.t_hour BETWEEN 9 AND 17
       GROUP BY sm.sm_ship_mode_id
     ),
     web_agg AS (
       SELECT sm.sm_ship_mode_id AS ship_mode_id,
              SUM(ws.ws_ext_sales_price) AS total_sales,
              'web' AS channel
       FROM web_sales ws
       JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
       JOIN time_dim td   ON ws.ws_sold_time_sk = td.t_time_sk
       WHERE td.t_hour BETWEEN 9 AND 17
       GROUP BY sm.sm_ship_mode_id
     )
SELECT ship_mode_id,
       total_sales,
       channel
FROM catalog_agg
UNION ALL
SELECT ship_mode_id,
       total_sales,
       channel
FROM web_agg
ORDER BY ship_mode_id, channel
LIMIT 100
