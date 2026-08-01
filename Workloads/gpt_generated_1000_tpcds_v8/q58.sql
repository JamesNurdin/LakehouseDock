SELECT
    inv_warehouse_sk,
    SUM(inv_quantity_on_hand) AS total_qty,
    COUNT(*) AS item_count
FROM tpcds.inventory
WHERE inv_item_sk IN (2, 28, 38)
  AND inv_quantity_on_hand > 500
GROUP BY inv_warehouse_sk
ORDER BY total_qty DESC
LIMIT 100
