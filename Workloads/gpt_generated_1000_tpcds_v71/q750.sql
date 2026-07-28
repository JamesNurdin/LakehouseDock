WITH catalog_data AS (
    SELECT
        i.i_category AS category,
        r.r_reason_desc AS reason,
        SUM(cr.cr_return_amount) AS total_return_amount,
        CASE WHEN SUM(cr.cr_net_loss) > 5000 THEN 'High' ELSE 'Low' END AS loss_level,
        'Catalog' AS channel
    FROM tpcds.catalog_returns cr
    JOIN tpcds.item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'CA'
    GROUP BY i.i_category, r.r_reason_desc
),
store_data AS (
    SELECT
        i.i_category AS category,
        r.r_reason_desc AS reason,
        SUM(sr.sr_return_amt) AS total_return_amount,
        CASE WHEN SUM(sr.sr_net_loss) > 3000 THEN 'High' ELSE 'Low' END AS loss_level,
        'Store' AS channel
    FROM tpcds.store_returns sr
    JOIN tpcds.item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY i.i_category, r.r_reason_desc
)
SELECT
    category,
    reason,
    total_return_amount,
    loss_level,
    channel
FROM (
    SELECT * FROM catalog_data
    UNION ALL
    SELECT * FROM store_data
) AS combined
ORDER BY total_return_amount DESC
LIMIT 100
