WITH avg_ref AS (
    SELECT AVG(inv_quantity_on_hand) AS avg_qty
    FROM inventory
    WHERE inv_warehouse_sk = 9
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
    SUM(i.inv_quantity_on_hand) AS total_qty,
    AVG(i.inv_quantity_on_hand) AS avg_qty,
    MIN(i.inv_quantity_on_hand) AS min_qty,
    MAX(i.inv_quantity_on_hand) AS max_qty
FROM inventory i
JOIN warehouse w
  ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.inv_warehouse_sk IN (9, 15, 16, 2)
  AND i.inv_date_sk BETWEEN 2450836 AND 2451067
  AND i.inv_quantity_on_hand >= 100
  AND w.w_state = 'CA'
  AND i.inv_quantity_on_hand > (SELECT avg_qty FROM avg_ref)
  AND EXISTS (
        SELECT 1 FROM warehouse w2
        WHERE w2.w_warehouse_sk = i.inv_warehouse_sk
          AND w2.w_zip LIKE '19___'
    )
GROUP BY w.w_warehouse_id, w.w_city, w.w_state
ORDER BY total_qty DESC
LIMIT 100
