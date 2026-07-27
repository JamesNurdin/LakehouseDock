WITH store_losses AS (
    SELECT i.i_item_id AS item_id,
           r.r_reason_desc AS reason_desc,
           SUM(sr.sr_net_loss) AS loss_amount
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_time_sk = 60645
    GROUP BY i.i_item_id, r.r_reason_desc
),
catalog_losses AS (
    SELECT i.i_item_id AS item_id,
           r.r_reason_desc AS reason_desc,
           SUM(cr.cr_net_loss) AS loss_amount
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_returned_time_sk = 60645
    GROUP BY i.i_item_id, r.r_reason_desc
)
SELECT DISTINCT item_id,
                reason_desc,
                loss_amount,
                'store' AS source
FROM store_losses
WHERE loss_amount > 10
UNION ALL
SELECT DISTINCT item_id,
                reason_desc,
                loss_amount,
                'catalog' AS source
FROM catalog_losses
WHERE loss_amount > 10
ORDER BY loss_amount DESC
LIMIT 100
