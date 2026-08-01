WITH sr AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_hdemo_sk,
        sr.sr_net_loss,
        sr.sr_fee,
        sr.sr_return_quantity,
        d_sr.d_year,
        i_sr.i_category
    FROM store_returns sr
    JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN item i_sr
        ON sr.sr_item_sk = i_sr.i_item_sk
    JOIN household_demographics hd_sr
        ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
),
cr AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_returning_hdemo_sk,
        cr.cr_call_center_sk,
        cr.cr_net_loss,
        cr.cr_fee,
        cr.cr_return_quantity,
        d_cr.d_year AS cr_year,
        i_cr.i_category AS cr_category
    FROM catalog_returns cr
    JOIN date_dim d_cr
        ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN item i_cr
        ON cr.cr_item_sk = i_cr.i_item_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret
        ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN call_center cc_cr
        ON cr.cr_call_center_sk = cc_cr.cc_call_center_sk
    JOIN date_dim d_cc
        ON cc_cr.cc_closed_date_sk = d_cc.d_date_sk
    JOIN date_dim d_cc2
        ON cc_cr.cc_open_date_sk = d_cc2.d_date_sk
)
SELECT
    sr.d_year AS year,
    sr.i_category AS category,
    cc2.cc_name AS call_center_name,
    SUM(sr.sr_net_loss) AS total_store_loss,
    SUM(cr.cr_net_loss) AS total_catalog_loss,
    COUNT(*) AS transaction_count,
    CASE
        WHEN SUM(sr.sr_net_loss + cr.cr_net_loss) > 10000 THEN 'High'
        ELSE 'Low'
    END AS loss_level
FROM sr
JOIN cr
    ON sr.sr_item_sk = cr.cr_item_sk
   AND sr.sr_returned_date_sk = cr.cr_returned_date_sk
JOIN call_center cc2
    ON cc2.cc_open_date_sk = sr.sr_returned_date_sk
GROUP BY
    sr.d_year,
    sr.i_category,
    cc2.cc_name
ORDER BY
    loss_level DESC,
    total_store_loss DESC
LIMIT 100
