SELECT
    inv_warehouse_sk,
    SUM(inv_quantity_on_hand) AS total_quantity_on_hand
FROM tpcds.inventory
WHERE inv_item_sk IN (101449, 101426, 101428)
  AND inv_warehouse_sk = 11
GROUP BY inv_warehouse_sk
ORDER BY total_quantity_on_hand DESC
