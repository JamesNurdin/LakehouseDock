WITH inventory_agg AS (
    SELECT
        ws.web_city,
        d.d_year,
        SUM(inv.inv_quantity_on_hand) AS metric_value,
        CASE WHEN SUM(inv.inv_quantity_on_hand) > 5000 THEN 'HighTotal' ELSE 'LowTotal' END AS category,
        'Inventory' AS record_type
    FROM (
        SELECT DISTINCT
            inv.inv_item_sk,
            inv.inv_warehouse_sk,
            inv.inv_quantity_on_hand,
            inv.inv_date_sk
        FROM inventory inv
    ) inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY ws.web_city, d.d_year
),
catalog_agg AS (
    SELECT
        ws.web_city,
        d.d_year,
        COUNT(cp.cp_catalog_page_number) AS metric_value,
        CASE WHEN COUNT(cp.cp_catalog_page_number) >= 10 THEN 'ManyPages' ELSE 'FewPages' END AS category,
        'Catalog' AS record_type
    FROM catalog_page cp
    JOIN date_dim d ON cp.cp_end_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_close_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY ws.web_city, d.d_year
)
SELECT *
FROM inventory_agg
UNION ALL
SELECT *
FROM catalog_agg
ORDER BY web_city, record_type
