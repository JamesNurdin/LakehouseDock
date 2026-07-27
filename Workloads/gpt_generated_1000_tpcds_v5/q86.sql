WITH inv_item_wh AS (
    SELECT
        i.i_item_sk,
        i.i_class_id,
        i.i_wholesale_cost,
        inv.inv_quantity_on_hand,
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE inv.inv_date_sk BETWEEN 2450955 AND 2451088
)
SELECT
    w_warehouse_id,
    w_warehouse_name,
    i_class_id,
    total_qty,
    avg_wholesale_cost,
    class_label
FROM (
    SELECT
        w_warehouse_id,
        w_warehouse_name,
        i_class_id,
        SUM(inv_quantity_on_hand) AS total_qty,
        AVG(i_wholesale_cost) AS avg_wholesale_cost,
        'Class14' AS class_label
    FROM inv_item_wh
    WHERE i_class_id = 14
    GROUP BY w_warehouse_id, w_warehouse_name, i_class_id
    HAVING SUM(inv_quantity_on_hand) > 500

    UNION ALL

    SELECT
        w_warehouse_id,
        w_warehouse_name,
        i_class_id,
        SUM(inv_quantity_on_hand) AS total_qty,
        AVG(i_wholesale_cost) AS avg_wholesale_cost,
        'Class8' AS class_label
    FROM inv_item_wh
    WHERE i_class_id = 8
    GROUP BY w_warehouse_id, w_warehouse_name, i_class_id
    HAVING SUM(inv_quantity_on_hand) > 500
) AS combined
ORDER BY total_qty DESC
LIMIT 100
