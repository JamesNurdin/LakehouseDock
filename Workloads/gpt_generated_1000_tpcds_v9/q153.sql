WITH store_ret AS (
    SELECT
        sr.sr_item_sk,
        SUM(sr.sr_return_amt) AS store_return_amount,
        SUM(sr.sr_net_loss) AS store_net_loss,
        MAX(sr.sr_returned_date_sk) AS last_store_return_date_sk
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_state = 'TX'
    GROUP BY sr.sr_item_sk
),
catalog_ret AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        MAX(cr.cr_returned_date_sk) AS last_catalog_return_date_sk
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Customer Not Satisfied'
    GROUP BY cr.cr_item_sk
),
item_latest_promo AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        p.p_promo_id,
        p.p_start_date_sk,
        p.p_cost
    FROM item i
    LEFT JOIN LATERAL (
        SELECT p2.p_promo_id, p2.p_start_date_sk, p2.p_cost
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
        ORDER BY p2.p_start_date_sk DESC
        LIMIT 1
    ) p ON TRUE
)
SELECT
    i.i_item_id AS item_id,
    sr.store_return_amount,
    cr.catalog_return_amount,
    COALESCE(sr.store_net_loss, 0) + COALESCE(cr.catalog_net_loss, 0) AS total_net_loss,
    p.p_promo_id,
    p.p_start_date_sk
FROM item i
FULL OUTER JOIN store_ret sr ON i.i_item_sk = sr.sr_item_sk
FULL OUTER JOIN catalog_ret cr ON i.i_item_sk = cr.cr_item_sk
LEFT JOIN item_latest_promo p ON i.i_item_sk = p.i_item_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_item_sk = i.i_item_sk
)
UNION
SELECT
    i2.i_item_id AS item_id,
    0 AS store_return_amount,
    0 AS catalog_return_amount,
    0 AS total_net_loss,
    p2.p_promo_id,
    p2.p_start_date_sk
FROM item i2
LEFT JOIN item_latest_promo p2 ON i2.i_item_sk = p2.i_item_sk
WHERE NOT EXISTS (
    SELECT 1 FROM store_ret sr2 WHERE sr2.sr_item_sk = i2.i_item_sk
)
AND NOT EXISTS (
    SELECT 1 FROM catalog_ret cr2 WHERE cr2.cr_item_sk = i2.i_item_sk
)
AND NOT EXISTS (
    SELECT 1 FROM web_returns wr2 WHERE wr2.wr_item_sk = i2.i_item_sk
)
ORDER BY total_net_loss DESC
OFFSET 0
LIMIT 100
