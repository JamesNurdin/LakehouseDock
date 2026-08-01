SELECT it.i_item_id,
       it.i_product_name,
       inv.inv_quantity_on_hand
FROM inventory AS inv
JOIN item AS it
  ON inv.inv_item_sk = it.i_item_sk
WHERE inv.inv_warehouse_sk = 13
  AND it.i_manager_id = 34
ORDER BY inv.inv_quantity_on_hand DESC
