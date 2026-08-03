WITH returns_agg AS (
    SELECT
        d.d_year AS year,
        cp.cp_department AS department,
        s.s_state AS state,
        SUM(cr.cr_net_loss) AS metric_value,
        CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'Loss' ELSE 'NoLoss' END AS metric_flag
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE cr.cr_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand = 'BrandX')
    GROUP BY CUBE (d.d_year, cp.cp_department, s.s_state)
),
inventory_agg AS (
    SELECT
        d.d_year AS year,
        cp.cp_department AS department,
        s.s_state AS state,
        SUM(inv.inv_quantity_on_hand) AS metric_value,
        CASE WHEN SUM(inv.inv_quantity_on_hand) > 1000 THEN 'High' ELSE 'Low' END AS metric_flag
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE i.i_category = 'Electronics'
    GROUP BY CUBE (d.d_year, cp.cp_department, s.s_state)
)
SELECT *
FROM returns_agg
UNION ALL
SELECT *
FROM inventory_agg
ORDER BY year DESC, department, state, metric_value DESC
LIMIT 100
