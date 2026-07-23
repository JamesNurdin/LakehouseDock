SELECT inv_warehouse_sk,
       COUNT(DISTINCT inv_item_sk) AS distinct_item_count
FROM inventory
WHERE inv_date_sk = 2450955
  AND inv_quantity_on_hand > 0
  AND inv_warehouse_sk IN (1, 2, 9)
GROUP BY inv_warehouse_sk
ORDER BY distinct_item_count DESC
LIMIT 100
