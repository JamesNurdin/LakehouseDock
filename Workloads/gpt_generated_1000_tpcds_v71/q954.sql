WITH web_profit AS (
   SELECT
       wsit.web_state AS region,
       SUM(ws.ws_net_profit) AS total_profit
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE d.d_year = 2001
     AND sm.sm_code = 'AIR'
   GROUP BY wsit.web_state
)
SELECT region,
       metric,
       metric_value
FROM (
   SELECT
       region,
       'WebProfit' AS metric,
       CAST(total_profit AS decimal(15,2)) AS metric_value
   FROM web_profit

   UNION ALL

   SELECT
       cc.cc_state AS region,
       'ClosedCalls' AS metric,
       CAST(COUNT(DISTINCT cc.cc_call_center_id) AS decimal(15,2)) AS metric_value
   FROM call_center cc
   JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY cc.cc_state
) AS combined
ORDER BY region, metric
LIMIT 100
