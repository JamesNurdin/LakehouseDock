WITH unioned AS (
   SELECT
      ws.ws_item_sk,
      ws.ws_warehouse_sk,
      ws.ws_net_profit,
      w.w_warehouse_name,
      MAP(ARRAY['quantity','net_paid'], ARRAY[ws.ws_quantity, ws.ws_net_paid]) AS metrics
   FROM tpcds.web_sales ws
   JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   WHERE ws.ws_sold_date_sk BETWEEN 2450950 AND 2450960

   UNION

   SELECT
      ws.ws_item_sk,
      ws.ws_warehouse_sk,
      ws.ws_net_profit,
      w.w_warehouse_name,
      MAP(ARRAY['quantity','net_paid'], ARRAY[ws.ws_quantity, ws.ws_net_paid]) AS metrics
   FROM tpcds.web_sales ws
   JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   WHERE wp.wp_autogen_flag = 'Y'
),
sampled AS (
   SELECT * FROM unioned TABLESAMPLE BERNOULLI (10)
),
expanded AS (
   SELECT
      u.ws_item_sk,
      u.ws_warehouse_sk,
      u.ws_net_profit,
      u.w_warehouse_name,
      m.key   AS metric_name,
      m.value AS metric_value
   FROM sampled u
   CROSS JOIN UNNEST(u.metrics) AS m (key, value)
),
final_set AS (
   SELECT ws_item_sk FROM expanded
   EXCEPT
   SELECT inv_item_sk FROM tpcds.inventory WHERE inv_date_sk = 2450948
)
SELECT
   e.ws_item_sk,
   e.ws_warehouse_sk,
   e.w_warehouse_name,
   SUM(CASE WHEN e.metric_name = 'net_paid' THEN e.metric_value ELSE 0 END) AS total_net_paid,
   SUM(CASE WHEN e.metric_name = 'quantity' THEN e.metric_value ELSE 0 END) AS total_quantity
FROM expanded e
WHERE e.ws_item_sk IN (SELECT ws_item_sk FROM final_set)
GROUP BY GROUPING SETS (
   (e.ws_warehouse_sk, e.w_warehouse_name),
   (e.ws_item_sk)
)
ORDER BY total_net_paid DESC
LIMIT 100
