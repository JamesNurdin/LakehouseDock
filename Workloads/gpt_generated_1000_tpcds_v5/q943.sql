WITH sales_returns_a AS (
   SELECT
       cp.cp_department,
       w.w_warehouse_name,
       i.i_class_id,
       cs.cs_quantity AS qty_sold,
       cs.cs_net_profit AS net_profit,
       cr.cr_return_quantity AS qty_returned,
       cr.cr_net_loss AS net_loss,
       inv.inv_quantity_on_hand AS inventory_on_hand
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
   JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE cp.cp_catalog_number = 10
     AND i.i_class_id = 9
     AND w.w_street_type = 'Avenue'
     AND w.w_county = 'Marshall County'
),
sales_returns_b AS (
   SELECT
       cp.cp_department,
       w.w_warehouse_name,
       i.i_class_id,
       cs.cs_quantity AS qty_sold,
       cs.cs_net_profit AS net_profit,
       cr.cr_return_quantity AS qty_returned,
       cr.cr_net_loss AS net_loss,
       inv.inv_quantity_on_hand AS inventory_on_hand
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
   JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE cp.cp_catalog_number = 13
     AND i.i_class_id = 11
     AND w.w_street_type = 'Road'
     AND w.w_county = 'Mobile County'
),
combined AS (
   SELECT * FROM sales_returns_a
   UNION ALL
   SELECT * FROM sales_returns_b
),
agg AS (
   SELECT
       cp_department,
       w_warehouse_name,
       i_class_id,
       SUM(qty_sold) AS total_qty_sold,
       SUM(net_profit) AS total_net_profit,
       SUM(qty_returned) AS total_qty_returned,
       SUM(net_loss) AS total_return_loss,
       SUM(inventory_on_hand) AS total_inventory
   FROM combined
   GROUP BY CUBE (cp_department, w_warehouse_name, i_class_id)
)
SELECT
   cp_department,
   w_warehouse_name,
   i_class_id,
   total_qty_sold,
   total_net_profit,
   total_qty_returned,
   total_return_loss,
   total_inventory,
   CASE
       WHEN total_inventory = 0 THEN NULL
       ELSE total_qty_sold / total_inventory
   END AS sell_through_rate
FROM agg
WHERE total_net_profit > 0
  AND total_return_loss < 1000
ORDER BY cp_department NULLS LAST, w_warehouse_name NULLS LAST
LIMIT 100
