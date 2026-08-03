WITH cr_base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_call_center_sk,
        cr.cr_ship_mode_sk,
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_refunded_hdemo_sk,
        cr.cr_returning_hdemo_sk,
        cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk IS NOT NULL
)
SELECT
    cc.cc_name,
    d_ret.d_year,
    sm.sm_type,
    w.w_city,
    CASE
        WHEN cr_base.cr_return_amount > 1000 THEN 'HIGH'
        WHEN cr_base.cr_return_amount BETWEEN 500 AND 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS amount_category,
    COUNT(DISTINCT cr_base.cr_order_number) AS distinct_orders,
    (
        SELECT SUM(sr.sr_return_amt)
        FROM store_returns sr
        WHERE sr.sr_returned_date_sk = cr_base.cr_returned_date_sk
          AND sr.sr_reason_sk = cr_base.cr_reason_sk
    ) AS store_return_amount_for_same_date_reason,
    (
        SELECT COUNT(*)
        FROM web_page wp
        WHERE wp.wp_creation_date_sk = cr_base.cr_returned_date_sk
    ) AS pages_created_on_return_date
FROM cr_base
JOIN call_center cc
    ON cc.cc_call_center_sk = cr_base.cr_call_center_sk
JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = cr_base.cr_ship_mode_sk
JOIN warehouse w
    ON w.w_warehouse_sk = cr_base.cr_warehouse_sk
JOIN reason r
    ON r.r_reason_sk = cr_base.cr_reason_sk
JOIN date_dim d_ret
    ON d_ret.d_date_sk = cr_base.cr_returned_date_sk
JOIN time_dim t_ret
    ON t_ret.t_time_sk = cr_base.cr_returned_time_sk
-- household demographics joined twice with different roles
JOIN household_demographics hd_ref
    ON hd_ref.hd_demo_sk = cr_base.cr_refunded_hdemo_sk
JOIN household_demographics hd_ret
    ON hd_ret.hd_demo_sk = cr_base.cr_returning_hdemo_sk
-- call center open date dimension (second use of date_dim)
JOIN date_dim d_open
    ON d_open.d_date_sk = cc.cc_open_date_sk
-- web page joined via access date (third use of date_dim)
LEFT JOIN web_page wp
    ON wp.wp_access_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year = 2001
GROUP BY
    cc.cc_name,
    d_ret.d_year,
    sm.sm_type,
    w.w_city,
    CASE
        WHEN cr_base.cr_return_amount > 1000 THEN 'HIGH'
        WHEN cr_base.cr_return_amount BETWEEN 500 AND 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END,
    cr_base.cr_returned_date_sk,
    cr_base.cr_reason_sk
ORDER BY distinct_orders DESC
LIMIT 100
