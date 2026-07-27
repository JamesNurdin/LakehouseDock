WITH returns AS (
   SELECT
       td.t_hour AS hour,
       'return_loss' AS metric,
       SUM(cr.cr_net_loss) AS amount,
       COUNT(*) AS cnt
   FROM catalog_returns cr
   JOIN time_dim td
       ON cr.cr_returned_time_sk = td.t_time_sk
   JOIN call_center cc
       ON cr.cr_call_center_sk = cc.cc_call_center_sk
   WHERE cc.cc_county = 'Levy County'
     AND td.t_hour BETWEEN 8 AND 12
     AND EXISTS (
         SELECT 1
         FROM catalog_returns cr2
         WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
           AND cr2.cr_reversed_charge > 200
     )
   GROUP BY td.t_hour
   HAVING SUM(cr.cr_net_loss) > 1000
),
sales AS (
   SELECT
       td.t_hour AS hour,
       'sales_profit' AS metric,
       SUM(ws.ws_net_profit) AS amount,
       COUNT(*) AS cnt
   FROM web_sales ws
   JOIN time_dim td
       ON ws.ws_sold_time_sk = td.t_time_sk
   WHERE ws.ws_quantity > 5
     AND td.t_hour BETWEEN 8 AND 12
   GROUP BY td.t_hour
   HAVING SUM(ws.ws_net_profit) > 500
)
SELECT *
FROM returns
UNION ALL
SELECT *
FROM sales
ORDER BY hour, metric, amount DESC
LIMIT 100
