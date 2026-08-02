SELECT inventory.inv_warehouse_sk,
       SUM(inventory.inv_quantity_on_hand) AS total_quantity_on_hand
FROM inventory
WHERE inventory.inv_date_sk = 2450850
  AND inventory.inv_quantity_on_hand > 500
GROUP BY inventory.inv_warehouse_sk
ORDER BY total_quantity_on_hand DESC
