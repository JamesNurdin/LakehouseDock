WITH returns AS (
    SELECT
        i.i_item_id AS item_id,
        d.d_year AS year,
        'return_amount' AS metric_type,
        SUM(cr.cr_return_amount) AS metric_value,
        CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'HIGH_LOSS' ELSE 'NORMAL' END AS category
    FROM catalog_returns AS cr
    JOIN date_dim AS d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item AS i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2020
    GROUP BY i.i_item_id, d.d_year
),
inventory_agg AS (
    SELECT
        i.i_item_id AS item_id,
        d.d_year AS year,
        'inventory_qty' AS metric_type,
        SUM(inv.inv_quantity_on_hand) AS metric_value,
        CASE WHEN SUM(inv.inv_quantity_on_hand) < 500 THEN 'LOW_STOCK' ELSE 'NORMAL' END AS category
    FROM inventory AS inv
    JOIN date_dim AS d ON inv.inv_date_sk = d.d_date_sk
    JOIN item AS i ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 2020
    GROUP BY i.i_item_id, d.d_year
)
SELECT * FROM returns
UNION ALL
SELECT * FROM inventory_agg
ORDER BY metric_value DESC
LIMIT 100
