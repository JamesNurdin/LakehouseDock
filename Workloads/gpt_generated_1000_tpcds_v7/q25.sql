WITH store_item_sales AS (
   SELECT
       i.i_item_id,
       i.i_product_name,
       td.t_meal_time,
       SUM(ss.ss_net_paid) AS total_net_paid,
       SUM(ss.ss_net_profit) AS total_profit,
       COUNT(*) AS txn_count,
       (
           SELECT AVG(inv_quantity_on_hand)
           FROM inventory inv
           WHERE inv.inv_item_sk = i.i_item_sk
       ) AS avg_inventory_on_hand
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
   WHERE td.t_meal_time IN ('lunch', 'dinner')
     AND ss.ss_quantity > 1
   GROUP BY i.i_item_id, i.i_product_name, td.t_meal_time, i.i_item_sk
   HAVING SUM(ss.ss_net_paid) > 10000
),
web_item_sales AS (
   SELECT
       i.i_item_id,
       i.i_product_name,
       td.t_meal_time,
       SUM(ws.ws_net_paid) AS total_net_paid,
       SUM(ws.ws_net_profit) AS total_profit,
       COUNT(*) AS txn_count,
       (
           SELECT AVG(inv_quantity_on_hand)
           FROM inventory inv
           WHERE inv.inv_item_sk = i.i_item_sk
       ) AS avg_inventory_on_hand
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   WHERE td.t_meal_time = 'breakfast'
     AND EXISTS (
         SELECT 1
         FROM warehouse w
         WHERE w.w_warehouse_sk = ws.ws_warehouse_sk
           AND w.w_state = 'CA'
     )
   GROUP BY i.i_item_id, i.i_product_name, td.t_meal_time, i.i_item_sk
   HAVING SUM(ws.ws_net_paid) > 8000
)
SELECT
   src.sales_channel,
   src.item_id,
   src.product_name,
   src.meal_time,
   src.total_net_paid,
   src.total_profit,
   src.txn_count,
   src.avg_inventory_on_hand
FROM (
   SELECT
       'store' AS sales_channel,
       i_item_id AS item_id,
       i_product_name AS product_name,
       t_meal_time AS meal_time,
       total_net_paid,
       total_profit,
       txn_count,
       avg_inventory_on_hand
   FROM store_item_sales

   UNION ALL

   SELECT
       'web' AS sales_channel,
       i_item_id,
       i_product_name,
       t_meal_time,
       total_net_paid,
       total_profit,
       txn_count,
       avg_inventory_on_hand
   FROM web_item_sales
) src
ORDER BY src.total_net_paid DESC
LIMIT 100
