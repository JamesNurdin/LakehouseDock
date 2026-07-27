WITH inventory_agg AS (
    SELECT
        w.w_warehouse_name AS entity_name,
        SUM(i.inv_quantity_on_hand) AS metric_value,
        'Warehouse_Inventory' AS metric_type
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
    GROUP BY w.w_warehouse_name
), callcenter_agg AS (
    SELECT
        cc.cc_division_name AS entity_name,
        COUNT(*) AS metric_value,
        'Division_CallCenter' AS metric_type
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cc.cc_division_name
)
SELECT entity_name, metric_value, metric_type
FROM inventory_agg
UNION ALL
SELECT entity_name, metric_value, metric_type
FROM callcenter_agg
ORDER BY metric_value DESC, entity_name
LIMIT 100
