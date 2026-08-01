WITH warehouse_inventory AS (
   SELECT
       w.w_warehouse_sk,
       w.w_warehouse_name,
       COALESCE(SUM(i.inv_quantity_on_hand), 0) AS total_quantity_on_hand
   FROM warehouse w
   LEFT JOIN inventory i
       ON i.inv_warehouse_sk = w.w_warehouse_sk
   GROUP BY w.w_warehouse_sk, w.w_warehouse_name
)

SELECT
   label,
   metric_value,
   status,
   row_num,
   extra_metric,
   overall_avg_profit
FROM (
   SELECT
       concat('Time ', CAST(td.t_hour AS varchar), ':', CAST(td.t_minute AS varchar)) AS label,
       COALESCE(SUM(ss.ss_net_paid), 0) AS metric_value,
       CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS status,
       ROW_NUMBER() OVER (ORDER BY td.t_hour, td.t_minute) AS row_num,
       CAST(NULL AS BIGINT) AS extra_metric,
       (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2) AS overall_avg_profit
   FROM store_sales ss
   RIGHT OUTER JOIN time_dim td
       ON ss.ss_sold_time_sk = td.t_time_sk
   GROUP BY td.t_hour, td.t_minute

   UNION ALL

   SELECT
       w.w_warehouse_name AS label,
       COALESCE(SUM(ws.ws_net_paid_inc_ship), 0) AS metric_value,
       CASE WHEN AVG(ws.ws_ext_ship_cost) > 1000 THEN 'HIGH_SHIP' ELSE 'NORMAL_SHIP' END AS status,
       ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY COALESCE(SUM(ws.ws_net_paid_inc_ship),0) DESC) AS row_num,
       wi.total_quantity_on_hand AS extra_metric,
       (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2) AS overall_avg_profit
   FROM web_sales ws
   RIGHT OUTER JOIN warehouse w
       ON ws.ws_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN warehouse_inventory wi
       ON wi.w_warehouse_sk = w.w_warehouse_sk
   GROUP BY w.w_warehouse_name, wi.total_quantity_on_hand
) AS combined
ORDER BY metric_value DESC, row_num
LIMIT 100
