WITH sales_agg AS (
   SELECT
      i.i_item_id,
      i.i_manufact,
      SUM(ws.ws_net_profit) AS total_profit,
      CASE
         WHEN SUM(ws.ws_net_profit) > 50000 THEN 'High'
         WHEN SUM(ws.ws_net_profit) > 20000 THEN 'Medium'
         ELSE 'Low'
      END AS profit_category,
      'sales' AS source
   FROM tpcds.web_sales ws
   JOIN tpcds.item i
     ON ws.ws_item_sk = i.i_item_sk
   WHERE i.i_rec_end_date = DATE '2000-10-26'
   GROUP BY i.i_item_id, i.i_manufact
   HAVING SUM(ws.ws_net_profit) > 1000
),
inventory_agg AS (
   SELECT
      i.i_item_id,
      i.i_manufact,
      SUM(inv.inv_quantity_on_hand) AS total_quantity,
      CASE
         WHEN SUM(inv.inv_quantity_on_hand) > 1000 THEN 'High'
         WHEN SUM(inv.inv_quantity_on_hand) > 500 THEN 'Medium'
         ELSE 'Low'
      END AS profit_category,
      'inventory' AS source
   FROM tpcds.inventory inv
   JOIN tpcds.item i
     ON inv.inv_item_sk = i.i_item_sk
   WHERE i.i_rec_end_date = DATE '2000-10-26'
   GROUP BY i.i_item_id, i.i_manufact
   HAVING SUM(inv.inv_quantity_on_hand) > 50
)
SELECT DISTINCT
   u.i_item_id,
   u.i_manufact,
   u.metric,
   u.profit_category,
   u.source
FROM (
   SELECT
      i_item_id,
      i_manufact,
      total_profit AS metric,
      profit_category,
      source
   FROM sales_agg
   UNION ALL
   SELECT
      i_item_id,
      i_manufact,
      total_quantity AS metric,
      profit_category,
      source
   FROM inventory_agg
) u
ORDER BY u.metric DESC
LIMIT 100
