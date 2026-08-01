SELECT i.i_item_id,
       i.i_product_name,
       SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
FROM inventory inv
JOIN item i
  ON inv.inv_item_sk = i.i_item_sk
WHERE i.i_formulation = '90papaya546284022999'
  AND inv.inv_warehouse_sk = 2
GROUP BY i.i_item_id, i.i_product_name
ORDER BY total_quantity_on_hand DESC
LIMIT 100
