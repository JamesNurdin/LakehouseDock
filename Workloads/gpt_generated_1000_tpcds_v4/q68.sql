WITH warehouse_inventory_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        d.d_year,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        (
            SELECT MAX(inv_quantity_on_hand)
            FROM inventory i2
            WHERE i2.inv_warehouse_sk = w.w_warehouse_sk
        ) AS max_qty_per_warehouse
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_weekend = 'N'
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, d.d_year
)
SELECT *
FROM (
    SELECT
        CAST('Warehouse' AS varchar) AS entity_type,
        wia.w_warehouse_name AS entity_name,
        wia.d_year AS year,
        wia.total_qty AS metric_value
    FROM warehouse_inventory_agg wia
    WHERE wia.total_qty > 10000

    UNION ALL

    SELECT
        CAST('WebSite' AS varchar) AS entity_type,
        ws.web_name AS entity_name,
        d_open.d_year AS year,
        ws.web_mkt_id AS metric_value
    FROM web_site ws
    JOIN date_dim d_open ON ws.web_open_date_sk = d_open.d_date_sk
    WHERE ws.web_country = 'United States'
      AND ws.web_mkt_id IN (1, 2, 3)
) combined
ORDER BY year DESC, metric_value DESC
LIMIT 100
