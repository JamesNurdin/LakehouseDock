WITH base_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_ship_mode_sk,
        cr.cr_reason_sk,
        sm.sm_carrier,
        sm.sm_contract,
        t.t_am_pm,
        t.t_hour,
        i.i_brand,
        i.i_category,
        hd.hd_income_band_sk
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
)
SELECT
    carrier,
    am_pm,
    loss_category,
    SUM(return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    ROUND(AVG(net_loss), 2) AS avg_net_loss,
    (SELECT AVG(ib_lower_bound) FROM income_band) AS avg_income_lower
FROM (
    SELECT
        br.sm_carrier AS carrier,
        br.t_am_pm AS am_pm,
        CASE WHEN br.cr_net_loss > 100 THEN 'High' ELSE 'Low' END AS loss_category,
        br.cr_return_amount AS return_amount,
        br.cr_net_loss AS net_loss,
        br.cr_reason_sk
    FROM base_returns br
    WHERE br.sm_carrier = 'UPS'
      AND br.t_am_pm = 'AM'
      AND EXISTS (
          SELECT 1 FROM reason r
          WHERE r.r_reason_sk = br.cr_reason_sk
            AND r.r_reason_desc = 'Customer'
      )
    UNION ALL
    SELECT
        br.sm_carrier,
        br.t_am_pm,
        CASE WHEN br.cr_net_loss > 100 THEN 'High' ELSE 'Low' END,
        br.cr_return_amount,
        br.cr_net_loss,
        br.cr_reason_sk
    FROM base_returns br
    WHERE br.sm_carrier = 'FEDEX'
      AND br.t_am_pm = 'PM'
      AND EXISTS (
          SELECT 1 FROM reason r
          WHERE r.r_reason_sk = br.cr_reason_sk
            AND r.r_reason_desc = 'Supplier'
      )
) AS combined
GROUP BY ROLLUP (carrier, am_pm, loss_category)
ORDER BY carrier, am_pm, loss_category
LIMIT 100
