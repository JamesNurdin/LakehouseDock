WITH joined_data AS (
   SELECT
       cc.cc_market_manager,
       cc.cc_tax_percentage,
       w.w_state,
       w.w_zip,
       sm.sm_type,
       td_cr.t_am_pm,
       ws.ws_quantity,
       cr.cr_return_amount,
       ws.ws_net_profit,
       sr.sr_return_tax,
       cr.cr_order_number
   FROM catalog_returns cr
   JOIN call_center cc
       ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm
       ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w
       ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN time_dim td_cr
       ON cr.cr_returned_time_sk = td_cr.t_time_sk
   JOIN store_returns sr
       ON sr.sr_return_time_sk = td_cr.t_time_sk
   JOIN web_sales ws
       ON ws.ws_sold_time_sk = td_cr.t_time_sk
          AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
          AND ws.ws_warehouse_sk = w.w_warehouse_sk
   WHERE
       cc.cc_tax_percentage > 0.05
       AND cc.cc_division = 4
       AND w.w_zip = '46098'
       AND td_cr.t_am_pm = 'PM'
       AND ws.ws_quantity > 5
       AND cr.cr_return_amount > 100
       AND sr.sr_return_tax < 10
)
SELECT
   CASE WHEN cc_tax_percentage > 0.07 THEN 'HIGH' ELSE 'LOW' END AS tax_category,
   cc_market_manager,
   w_state,
   sm_type,
   COUNT(DISTINCT cr_order_number) AS distinct_orders,
   SUM(cr_return_amount) AS total_return_amount,
   AVG(ws_net_profit) AS avg_net_profit,
   MIN(sr_return_tax) AS min_return_tax,
   MAX(ws_quantity) AS max_quantity
FROM joined_data
GROUP BY
   CASE WHEN cc_tax_percentage > 0.07 THEN 'HIGH' ELSE 'LOW' END,
   cc_market_manager,
   w_state,
   sm_type
ORDER BY total_return_amount DESC
LIMIT 100
