WITH return_summary AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_state,
        sm.sm_type,
        cd.cd_gender,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_tax) AS avg_return_tax
    FROM
        catalog_returns cr
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE
        cr.cr_return_amt_inc_tax > 1000
        AND cr.cr_refunded_cash > 100
        AND sm.sm_code IN ('AIR', 'SEA')
        AND cd.cd_gender = 'F'
        AND w.w_state = 'CA'
    GROUP BY
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_state,
        sm.sm_type,
        cd.cd_gender
    HAVING
        SUM(cr.cr_return_amt_inc_tax) > 2000
)
SELECT
    w_warehouse_id,
    w_warehouse_name,
    w_state,
    sm_type,
    cd_gender,
    total_return_amount,
    return_cnt,
    avg_return_tax,
    RANK() OVER (PARTITION BY w_state ORDER BY total_return_amount DESC) AS state_warehouse_rank,
    ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS overall_rank
FROM
    return_summary
ORDER BY
    total_return_amount DESC
LIMIT 100
