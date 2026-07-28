WITH sales_data AS (
    SELECT
        dd.d_year AS year,
        CASE WHEN ws.ws_quantity > 10 THEN 'Bulk' ELSE 'Regular' END AS category,
        'sales' AS metric_type,
        SUM(ws.ws_ext_sales_price) AS total_amount
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE dd.d_year = 2001
      AND sm.sm_type = 'AIR'
    GROUP BY
        dd.d_year,
        CASE WHEN ws.ws_quantity > 10 THEN 'Bulk' ELSE 'Regular' END
    HAVING SUM(ws.ws_ext_sales_price) > 10000
),
inventory_data AS (
    SELECT
        dd.d_year AS year,
        CASE WHEN inv.inv_quantity_on_hand > 100 THEN 'High Stock' ELSE 'Low Stock' END AS category,
        'inventory' AS metric_type,
        SUM(inv.inv_quantity_on_hand) AS total_amount
    FROM inventory inv
    JOIN date_dim dd ON inv.inv_date_sk = dd.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE dd.d_year = 2001
    GROUP BY
        dd.d_year,
        CASE WHEN inv.inv_quantity_on_hand > 100 THEN 'High Stock' ELSE 'Low Stock' END
    HAVING SUM(inv.inv_quantity_on_hand) > 5000
)
SELECT
    year,
    category,
    metric_type,
    total_amount
FROM sales_data
UNION ALL
SELECT
    year,
    category,
    metric_type,
    total_amount
FROM inventory_data
ORDER BY year, metric_type, category
