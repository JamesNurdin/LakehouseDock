WITH category_inventory AS (
    SELECT
        i.i_category AS category,
        w.w_warehouse_name AS warehouse,
        SUM(inv.inv_quantity_on_hand) AS total_qty,
        (SELECT AVG(i2.i_current_price)
         FROM item i2
         WHERE i2.i_category = i.i_category) AS avg_price
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_category_id IN (1, 5, 6)
      AND w.w_warehouse_sq_ft > 200000
    GROUP BY i.i_category, w.w_warehouse_name
)
SELECT category, warehouse, total_qty, avg_price
FROM category_inventory
UNION ALL
SELECT
    i.i_category AS category,
    w.w_warehouse_name AS warehouse,
    SUM(inv.inv_quantity_on_hand) AS total_qty,
    (SELECT AVG(i2.i_current_price)
     FROM item i2
     WHERE i2.i_category = i.i_category) AS avg_price
FROM inventory inv
JOIN item i ON inv.inv_item_sk = i.i_item_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.i_manager_id = 27
  AND w.w_suite_number LIKE 'Suite %'
GROUP BY i.i_category, w.w_warehouse_name
ORDER BY total_qty DESC, category
LIMIT 100
