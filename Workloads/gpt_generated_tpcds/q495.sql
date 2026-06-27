WITH wh_inventory AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_state,
        w.w_city,
        w.w_warehouse_sq_ft,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
        AVG(i.inv_quantity_on_hand) AS avg_quantity_per_item
    FROM inventory i
    JOIN warehouse w
      ON i.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_state,
        w.w_city,
        w.w_warehouse_sq_ft
)
SELECT
    w_warehouse_id,
    w_warehouse_name,
    w_state,
    w_city,
    total_quantity,
    distinct_items,
    avg_quantity_per_item,
    total_quantity / w_warehouse_sq_ft AS quantity_per_sq_ft
FROM wh_inventory
ORDER BY total_quantity DESC
LIMIT 10
