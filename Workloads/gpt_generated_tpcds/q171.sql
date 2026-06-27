WITH all_returns AS (
    SELECT
        sr_returned_date_sk AS returned_date_sk,
        sr_reason_sk       AS reason_sk,
        sr_item_sk         AS item_sk,
        sr_return_quantity AS return_qty,
        sr_net_loss        AS net_loss,
        'store'   AS channel
    FROM store_returns
    UNION ALL
    SELECT
        cr_returned_date_sk,
        cr_reason_sk,
        cr_item_sk,
        cr_return_quantity,
        cr_net_loss,
        'catalog' AS channel
    FROM catalog_returns
    UNION ALL
    SELECT
        wr_returned_date_sk,
        wr_reason_sk,
        wr_item_sk,
        wr_return_quantity,
        wr_net_loss,
        'web'    AS channel
    FROM web_returns
)
SELECT
    d.d_year,
    d.d_moy,
    i.i_category,
    r.r_reason_desc,
    ret.channel,
    SUM(ret.return_qty) AS total_return_quantity,
    SUM(ret.net_loss)   AS total_net_loss
FROM all_returns ret
JOIN date_dim d   ON ret.returned_date_sk = d.d_date_sk
JOIN reason   r   ON ret.reason_sk        = r.r_reason_sk
JOIN item     i   ON ret.item_sk          = i.i_item_sk
WHERE d.d_date >= DATE '2020-01-01'
  AND d.d_date <  DATE '2021-01-01'
GROUP BY d.d_year, d.d_moy, i.i_category, r.r_reason_desc, ret.channel
ORDER BY d.d_year, d.d_moy, i.i_category, r.r_reason_desc, ret.channel
