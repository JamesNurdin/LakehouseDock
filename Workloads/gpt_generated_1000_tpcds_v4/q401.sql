SELECT DISTINCT inventory.inv_item_sk,
                inventory.inv_warehouse_sk,
                inventory.inv_quantity_on_hand
FROM tpcds.inventory AS inventory
WHERE inventory.inv_warehouse_sk IN (10, 20)
  AND inventory.inv_quantity_on_hand > 500
LIMIT 100
