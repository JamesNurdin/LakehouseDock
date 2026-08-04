WITH warehouse_inventory AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_city,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        COUNT(*) AS item_count
    FROM inventory i
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_quantity_on_hand > 0
      AND w.w_state IN ('CA', 'TX', 'NY')
    GROUP BY w.w_warehouse_sk, w.w_warehouse_id, w.w_city
)
SELECT w_warehouse_id, w_city, total_qty
FROM warehouse_inventory
WHERE total_qty >= 1000
EXCEPT
SELECT w_warehouse_id, w_city, total_qty
FROM warehouse_inventory
WHERE total_qty < 500
ORDER BY w_warehouse_id
LIMIT 100
