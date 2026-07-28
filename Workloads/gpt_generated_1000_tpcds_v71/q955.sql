WITH return_stats AS (
   SELECT
      sm.sm_ship_mode_id AS ship_mode_id,
      td.t_hour AS hour_of_day,
      SUM(cr.cr_return_amount) AS total_amount,
      COUNT(*) AS txn_count,
      ROW_NUMBER() OVER (PARTITION BY sm.sm_ship_mode_id ORDER BY SUM(cr.cr_return_amount) DESC) AS rn
   FROM catalog_returns cr
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN time_dim td   ON cr.cr_returned_time_sk = td.t_time_sk
   WHERE td.t_second IN (7, 13)
   GROUP BY sm.sm_ship_mode_id, td.t_hour
),
sales_stats AS (
   SELECT
      sm.sm_ship_mode_id AS ship_mode_id,
      td.t_hour AS hour_of_day,
      SUM(ws.ws_ext_sales_price) AS total_amount,
      COUNT(*) AS txn_count,
      ROW_NUMBER() OVER (PARTITION BY sm.sm_ship_mode_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rn
   FROM web_sales ws
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN time_dim td   ON ws.ws_sold_time_sk = td.t_time_sk
   WHERE td.t_second IN (7, 13)
     AND ws.ws_list_price > 50
   GROUP BY sm.sm_ship_mode_id, td.t_hour
)
SELECT
   ship_mode_id,
   hour_of_day,
   total_amount,
   txn_count,
   'RETURN' AS source_type,
   CASE WHEN total_amount > 1000 THEN 'HIGH' ELSE 'LOW' END AS amount_category,
   rn
FROM return_stats
UNION ALL
SELECT
   ship_mode_id,
   hour_of_day,
   total_amount,
   txn_count,
   'SALES' AS source_type,
   CASE WHEN total_amount > 5000 THEN 'HIGH' ELSE 'LOW' END AS amount_category,
   rn
FROM sales_stats
ORDER BY ship_mode_id, hour_of_day, source_type
LIMIT 100
