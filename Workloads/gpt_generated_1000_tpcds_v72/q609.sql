WITH returns_agg AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        i.i_category AS category,
        SUM(cr.cr_return_amount) AS metric_value,
        'Return' AS metric_type,
        CASE WHEN SUM(cr.cr_return_amount) > 1000 THEN 'High' ELSE 'Low' END AS level
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE td.t_time BETWEEN 8 AND 12
      AND cr.cr_return_amount > 20
    GROUP BY w.w_warehouse_name, i.i_category
    HAVING SUM(cr.cr_return_amount) > 500
),
inventory_agg AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        i.i_category AS category,
        SUM(inv.inv_quantity_on_hand) AS metric_value,
        'Inventory' AS metric_type,
        CASE WHEN SUM(inv.inv_quantity_on_hand) > 500 THEN 'High Stock' ELSE 'Low Stock' END AS level
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE inv.inv_date_sk BETWEEN 2450900 AND 2451100
      AND inv.inv_quantity_on_hand > 0
    GROUP BY w.w_warehouse_name, i.i_category
    HAVING SUM(inv.inv_quantity_on_hand) > 200
)
SELECT
    combined.warehouse_name,
    combined.category,
    combined.metric_value,
    combined.metric_type,
    combined.level
FROM (
    SELECT warehouse_name, category, metric_value, metric_type, level FROM returns_agg
    UNION ALL
    SELECT warehouse_name, category, metric_value, metric_type, level FROM inventory_agg
) AS combined
ORDER BY combined.metric_value DESC
LIMIT 100
