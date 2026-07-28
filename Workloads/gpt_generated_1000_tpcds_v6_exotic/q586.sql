WITH combined AS (
    SELECT
        d.d_date AS date,
        r.r_reason_desc AS reason_desc,
        cr.cr_net_loss AS net_loss,
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_reason_sk AS reason_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_refunded_cdemo_sk AS cd_sk,
        cr.cr_call_center_sk AS cc_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2001
      AND i.i_wholesale_cost > 1.00
      AND cc.cc_gmt_offset BETWEEN -5 AND 5
      AND r.r_reason_id LIKE 'AAAAAAA%'
      AND cr.cr_store_credit > 10
    UNION ALL
    SELECT
        d.d_date AS date,
        r.r_reason_desc AS reason_desc,
        sr.sr_net_loss AS net_loss,
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_reason_sk AS reason_sk,
        sr.sr_item_sk AS item_sk,
        sr.sr_cdemo_sk AS cd_sk,
        NULL AS cc_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND i.i_wholesale_cost > 1.00
      AND r.r_reason_id LIKE 'AAAAAAA%'
      AND sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 20
)
SELECT
    date,
    reason_desc,
    SUM(net_loss) AS total_net_loss,
    RANK() OVER (PARTITION BY date ORDER BY SUM(net_loss) DESC) AS loss_rank
FROM combined
GROUP BY date, reason_desc
ORDER BY date, loss_rank
