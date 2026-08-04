WITH sr AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_item_sk AS item_sk,
        sr.sr_net_loss AS net_loss
    FROM store_returns sr
),
cr AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
),
full_join AS (
    SELECT
        COALESCE(sr.date_sk, cr.date_sk) AS date_sk,
        COALESCE(sr.item_sk, cr.item_sk) AS item_sk,
        COALESCE(sr.net_loss, 0) - COALESCE(cr.net_loss, 0) AS net_loss_diff
    FROM sr
    FULL OUTER JOIN cr
        ON sr.date_sk = cr.date_sk
       AND sr.item_sk = cr.item_sk
),
full_set AS (
    SELECT DISTINCT date_sk, item_sk FROM full_join
),
web_set AS (
    SELECT DISTINCT
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_item_sk AS item_sk
    FROM web_returns wr
),
filtered_set AS (
    SELECT date_sk, item_sk
    FROM full_set
    EXCEPT
    SELECT date_sk, item_sk FROM web_set
)
SELECT
    d.d_date AS return_date,
    i.i_item_id,
    COALESCE(fj.net_loss_diff, 0) AS net_loss_diff
FROM filtered_set fs
JOIN full_join fj
    ON fs.date_sk = fj.date_sk AND fs.item_sk = fj.item_sk
JOIN date_dim d
    ON fs.date_sk = d.d_date_sk
JOIN item i
    ON fs.item_sk = i.i_item_sk
ORDER BY net_loss_diff DESC
LIMIT 100
