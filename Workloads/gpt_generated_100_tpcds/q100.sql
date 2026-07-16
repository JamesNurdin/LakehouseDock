WITH returns_with_time AS (
    SELECT
        cr.cr_call_center_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_fee,
        cr.cr_net_loss,
        td.t_shift,
        td.t_meal_time
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
)
SELECT
    cc.cc_name,
    cc.cc_state,
    rwt.t_shift,
    rwt.t_meal_time,
    COUNT(*) AS num_returns,
    SUM(rwt.cr_return_quantity) AS total_quantity,
    SUM(rwt.cr_return_amount) AS total_amount,
    SUM(rwt.cr_net_loss) AS total_net_loss,
    AVG(rwt.cr_return_tax) AS avg_return_tax,
    AVG(rwt.cr_fee) AS avg_fee
FROM returns_with_time rwt
JOIN call_center cc
    ON rwt.cr_call_center_sk = cc.cc_call_center_sk
GROUP BY
    cc.cc_name,
    cc.cc_state,
    rwt.t_shift,
    rwt.t_meal_time
ORDER BY total_net_loss DESC
LIMIT 25
