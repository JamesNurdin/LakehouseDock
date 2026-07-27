WITH catalog_data AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_size AS item_size,
        r.r_reason_desc AS reason_desc,
        cr.cr_return_quantity AS return_qty,
        cr.cr_net_loss AS net_loss,
        CASE WHEN cr.cr_net_loss > 500 THEN 'High' ELSE 'Low' END AS loss_category
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 200
),
store_data AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_size AS item_size,
        r.r_reason_desc AS reason_desc,
        sr.sr_return_quantity AS return_qty,
        sr.sr_net_loss AS net_loss,
        CASE WHEN sr.sr_net_loss > 500 THEN 'High' ELSE 'Low' END AS loss_category
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_amt > 200
)
SELECT
    item_id,
    item_size,
    reason_desc,
    return_qty,
    net_loss,
    loss_category
FROM catalog_data
UNION ALL
SELECT
    item_id,
    item_size,
    reason_desc,
    return_qty,
    net_loss,
    loss_category
FROM store_data
ORDER BY net_loss DESC
LIMIT 100
