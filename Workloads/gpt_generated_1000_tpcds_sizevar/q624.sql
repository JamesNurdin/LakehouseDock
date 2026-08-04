SELECT inv.inv_warehouse_sk,
       SUM(inv.inv_quantity_on_hand) AS total_qty,
       COUNT(DISTINCT itm.i_item_id) AS distinct_items
FROM inventory AS inv
JOIN item AS itm
  ON inv.inv_item_sk = itm.i_item_sk
WHERE inv.inv_quantity_on_hand > 500
  AND itm.i_color = 'wheat'
GROUP BY inv.inv_warehouse_sk
ORDER BY total_qty DESC
