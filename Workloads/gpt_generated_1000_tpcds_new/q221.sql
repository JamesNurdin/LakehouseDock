WITH item_intersection AS (
   SELECT ws_item_sk
   FROM web_sales
   WHERE ws_net_paid_inc_tax > 1000
   INTERSECT
   SELECT ws_item_sk
   FROM web_sales
   WHERE ws_ext_tax < 300
)
SELECT
   d.d_year,
   d.d_month_seq,
   i.inv_warehouse_sk,
   COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
   SUM(ws.ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
   AVG(ws.ws_ext_tax) AS avg_ext_tax,
   MIN(ws.ws_net_profit) AS min_net_profit,
   MAX(ws.ws_net_profit) AS max_net_profit,
   CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Overall Profit' ELSE 'Overall Loss' END AS profit_status
FROM web_sales ws
JOIN date_dim d
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN inventory i
  ON i.inv_date_sk = d.d_date_sk
JOIN item_intersection ii
  ON ws.ws_item_sk = ii.ws_item_sk
WHERE
  d.d_moy = 5
  AND d.d_dom = 19
  AND i.inv_item_sk = 101446
  AND i.inv_warehouse_sk IN (3, 7)
  AND ws.ws_quantity > 1
  AND ws.ws_net_paid_inc_tax < 5000
GROUP BY
  d.d_year,
  d.d_month_seq,
  i.inv_warehouse_sk
ORDER BY
  total_net_paid_inc_tax DESC
LIMIT 100
