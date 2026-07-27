WITH inv_agg AS (
    SELECT
        i.i_item_sk,
        w.w_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_sk, w.w_warehouse_sk
)
SELECT DISTINCT
    year,
    month_seq,
    item_id,
    inventory_on_hand,
    metric_value,
    rank,
    source_type
FROM (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        i.i_item_id AS item_id,
        inv.total_on_hand AS inventory_on_hand,
        SUM(cs.cs_net_profit) AS metric_value,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_net_profit) DESC) AS rank,
        'sales' AS source_type
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN inv_agg inv ON i.i_item_sk = inv.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, i.i_item_id, inv.total_on_hand

    UNION ALL

    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        i.i_item_id AS item_id,
        inv.total_on_hand AS inventory_on_hand,
        -SUM(cr.cr_net_loss) AS metric_value,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cr.cr_net_loss) ASC) AS rank,
        'returns' AS source_type
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN inv_agg inv ON i.i_item_sk = inv.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, i.i_item_id, inv.total_on_hand
) AS combined
ORDER BY year, month_seq, metric_value DESC
LIMIT 100
