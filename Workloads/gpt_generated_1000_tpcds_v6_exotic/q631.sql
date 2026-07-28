WITH base_dates AS (
    SELECT d_date_sk,
           d_date,
           d_year,
           d_month_seq
    FROM date_dim
    WHERE d_year = 2001
),
returns_data AS (
    SELECT
        d.d_date AS report_date,
        i.i_item_id AS i_item_id,
        'return' AS metric,
        SUM(sr.sr_net_loss) AS amount,
        CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Loss' ELSE 'NoLoss' END AS flag
    FROM store_returns sr
    JOIN base_dates d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
    GROUP BY d.d_date, i.i_item_id
),
inventory_data AS (
    SELECT
        d.d_date AS report_date,
        i.i_item_id AS i_item_id,
        'inventory' AS metric,
        SUM(inv.inv_quantity_on_hand) AS amount,
        CASE WHEN SUM(inv.inv_quantity_on_hand) > 0 THEN 'Positive' ELSE 'ZeroOrNeg' END AS flag
    FROM inventory inv
    JOIN base_dates d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'CA'
    GROUP BY d.d_date, i.i_item_id
)
SELECT *
FROM (
    SELECT report_date, i_item_id, metric, amount, flag FROM returns_data
    UNION ALL
    SELECT report_date, i_item_id, metric, amount, flag FROM inventory_data
) AS combined
ORDER BY report_date DESC, metric
