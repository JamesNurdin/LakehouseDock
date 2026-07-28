WITH cr AS (
   SELECT
       cr.cr_order_number,
       cr.cr_return_amount,
       cr.cr_return_tax,
       cr.cr_return_amt_inc_tax,
       cr.cr_net_loss,
       cr.cr_call_center_sk,
       cr.cr_ship_mode_sk,
       cr.cr_reason_sk,
       cr.cr_returned_time_sk
   FROM catalog_returns cr
   WHERE cr.cr_return_quantity > 0
),
wr AS (
   SELECT
       wr.wr_order_number,
       wr.wr_return_amt,
       wr.wr_return_tax,
       wr.wr_return_amt_inc_tax,
       wr.wr_net_loss,
       wr.wr_reason_sk,
       wr.wr_returned_time_sk
   FROM web_returns wr
   WHERE wr.wr_return_quantity > 0
)
SELECT
    cc.cc_state,
    sm.sm_type,
    r.r_reason_desc,
    td.t_hour,
    COUNT(DISTINCT cr.cr_order_number)          AS catalog_return_orders,
    COUNT(DISTINCT wr.wr_order_number)          AS web_return_orders,
    SUM(cr.cr_return_amount)                    AS total_catalog_return_amount,
    SUM(wr.wr_return_amt)                       AS total_web_return_amount,
    AVG(cr.cr_net_loss)                         AS avg_catalog_net_loss,
    AVG(wr.wr_net_loss)                         AS avg_web_net_loss,
    MIN(cr.cr_return_amount)                    AS min_catalog_return_amount,
    MAX(wr.wr_return_amt)                       AS max_web_return_amount
FROM cr
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm   ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r       ON cr.cr_reason_sk = r.r_reason_sk
JOIN time_dim td    ON cr.cr_returned_time_sk = td.t_time_sk
JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
                      AND wr.wr_reason_sk = r.r_reason_sk
WHERE
    sm.sm_code IN ('SEA', 'AIR')
    AND td.t_minute = 14
    AND r.r_reason_desc = 'Customer not satisfied'
    AND cc.cc_state = 'CA'
GROUP BY
    cc.cc_state,
    sm.sm_type,
    r.r_reason_desc,
    td.t_hour
ORDER BY
    total_catalog_return_amount DESC
LIMIT 100
