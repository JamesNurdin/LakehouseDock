WITH carrier_avg AS (
   SELECT sm.sm_carrier,
          AVG(ws.ws_net_profit) AS avg_profit
   FROM   web_sales ws
   JOIN   ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   GROUP BY sm.sm_carrier
),
unioned AS (
   SELECT w.w_state,
          sm.sm_carrier,
          SUM(ws.ws_net_profit) AS profit,
          COUNT(*) AS orders
   FROM   web_sales ws
   JOIN   ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN   warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   WHERE  ws.ws_wholesale_cost > 30.00
     AND  EXISTS (
            SELECT 1
            FROM   warehouse w2
            WHERE  w2.w_state = w.w_state
              AND  w2.w_zip LIKE '3%'
          )
   GROUP BY GROUPING SETS (
       (w.w_state, sm.sm_carrier),
       (w.w_state),
       (sm.sm_carrier)
   )
   UNION ALL
   SELECT w.w_state,
          sm.sm_carrier,
          SUM(ws.ws_net_profit) AS profit,
          COUNT(*) AS orders
   FROM   web_sales ws
   JOIN   ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN   warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   WHERE  sm.sm_contract = 'O9V6oF8RJnLMmZYd1'
     AND  ws.ws_list_price < 100.00
     AND  EXISTS (
            SELECT 1
            FROM   warehouse w2
            WHERE  w2.w_state = w.w_state
              AND  w2.w_zip LIKE '5%'
          )
   GROUP BY GROUPING SETS (
       (w.w_state, sm.sm_carrier),
       (w.w_state),
       (sm.sm_carrier)
   )
)
SELECT u.w_state,
       u.sm_carrier,
       u.profit,
       u.orders,
       ROW_NUMBER() OVER (ORDER BY u.profit DESC) AS rn
FROM   unioned u
JOIN   carrier_avg ca ON u.sm_carrier = ca.sm_carrier
WHERE  u.profit > ca.avg_profit
ORDER BY u.profit DESC, rn
LIMIT 100
