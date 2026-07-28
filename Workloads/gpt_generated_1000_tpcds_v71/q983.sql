WITH inventory_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        'inventory' AS metric_type,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        CASE WHEN SUM(i.inv_quantity_on_hand) > 50000 THEN 'HIGH' ELSE 'LOW' END AS quantity_category
    FROM inventory i
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_id, w.w_warehouse_name
),
returns_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        'returns' AS metric_type,
        SUM(cr.cr_return_quantity) AS total_quantity,
        CASE WHEN SUM(cr.cr_return_quantity) > 1000 THEN 'HIGH' ELSE 'LOW' END AS quantity_category
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_id, w.w_warehouse_name
)
SELECT
    w_warehouse_id,
    w_warehouse_name,
    metric_type,
    total_quantity,
    quantity_category
FROM inventory_agg
UNION ALL
SELECT
    w_warehouse_id,
    w_warehouse_name,
    metric_type,
    total_quantity,
    quantity_category
FROM returns_agg
ORDER BY total_quantity DESC
LIMIT 100
