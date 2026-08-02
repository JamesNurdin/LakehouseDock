WITH warehouse_inventory_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_street_name,
        w.w_street_type,
        w.w_state,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items
    FROM
        inventory i
        JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        i.inv_quantity_on_hand > 200
        AND i.inv_quantity_on_hand < 1000
        AND i.inv_date_sk BETWEEN 2450800 AND 2451100
        AND w.w_street_name IN ('Ridge', 'Center', 'Oak Ninth')
        AND w.w_street_type IN ('Ln', 'Ct.', 'Parkway')
        AND w.w_zip LIKE '9%'
        AND w.w_state NOT IN ('NV', 'UT')
        AND w.w_gmt_offset > -5.00
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_street_name,
        w.w_street_type,
        w.w_state
),
selected_warehouses AS (
    SELECT w_warehouse_sk FROM warehouse WHERE w_state = 'CA' AND w_street_name = 'Ridge'
    UNION
    SELECT w_warehouse_sk FROM warehouse WHERE w_state = 'TX' AND w_street_type = 'Parkway'
),
high_qty_warehouses AS (
    SELECT inv_warehouse_sk AS w_warehouse_sk FROM inventory WHERE inv_quantity_on_hand > 800
),
low_qty_warehouses AS (
    SELECT DISTINCT inv_warehouse_sk AS w_warehouse_sk FROM inventory WHERE inv_quantity_on_hand < 300
),
common_qty_warehouses AS (
    SELECT w_warehouse_sk FROM high_qty_warehouses
    INTERSECT
    SELECT w_warehouse_sk FROM low_qty_warehouses
)
SELECT
    wa.w_warehouse_name,
    wa.w_street_name,
    wa.w_street_type,
    wa.w_state,
    wa.total_qty,
    wa.distinct_items,
    AVG(wa.total_qty) OVER () AS avg_total_qty_all_warehouses
FROM
    warehouse_inventory_agg wa
WHERE
    wa.w_warehouse_sk IN (SELECT w_warehouse_sk FROM selected_warehouses)
    AND wa.w_warehouse_sk NOT IN (SELECT w_warehouse_sk FROM common_qty_warehouses)
    AND EXISTS (
        SELECT 1 FROM inventory i3
        WHERE i3.inv_warehouse_sk = wa.w_warehouse_sk
          AND i3.inv_quantity_on_hand > 900
    )
    AND NOT EXISTS (
        SELECT 1 FROM inventory i4
        WHERE i4.inv_warehouse_sk = wa.w_warehouse_sk
          AND i4.inv_quantity_on_hand = 0
    )
ORDER BY
    wa.total_qty DESC,
    wa.w_warehouse_name
LIMIT 100
