WITH base_returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        d_ret.d_year,
        t_ret.t_hour,
        sm.sm_carrier,
        r.r_reason_desc,
        cc.cc_name,
        cp.cp_department,
        ca_ref.ca_state          AS refund_state,
        ca_ret.ca_state          AS return_state,
        cd_ref.cd_gender         AS refund_gender,
        cd_ret.cd_gender         AS return_gender
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    WHERE EXISTS (
        SELECT 1
        FROM ship_mode sm2
        WHERE sm2.sm_ship_mode_sk = cr.cr_ship_mode_sk
          AND sm2.sm_carrier = 'FEDEX'
    )
)
SELECT
    d_year,
    sm_carrier,
    cp_department,
    cc_name,
    SUM(cr_return_amount)        AS total_return_amount,
    COUNT(DISTINCT cr_order_number) AS orders_returned
FROM base_returns
WHERE d_year BETWEEN 2000 AND 2001
GROUP BY d_year, sm_carrier, cp_department, cc_name

UNION ALL

SELECT
    d_year,
    sm_carrier,
    cp_department,
    cc_name,
    SUM(cr_return_amount)        AS total_return_amount,
    COUNT(DISTINCT cr_order_number) AS orders_returned
FROM base_returns
WHERE d_year BETWEEN 2002 AND 2003
GROUP BY d_year, sm_carrier, cp_department, cc_name

ORDER BY d_year DESC, total_return_amount DESC
LIMIT 100
