WITH filtered AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_zip,
        cc.cc_state,
        t.t_hour,
        t.t_am_pm,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_store_credit,
        cr.cr_return_ship_cost,
        cr.cr_reversed_charge
    FROM catalog_returns cr
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim t
      ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE cc.cc_zip IN ('26534', '53951')
      AND cr.cr_store_credit > 1000
      AND cr.cr_return_ship_cost < 500
      AND cr.cr_reversed_charge BETWEEN 20 AND 50
      AND t.t_am_pm = 'PM'
),
grouped AS (
    SELECT
        cc_call_center_id,
        cc_zip,
        t_hour,
        COUNT(*) AS return_cnt,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_tax) AS avg_return_tax,
        MIN(cr_return_ship_cost) AS min_ship_cost,
        MAX(cr_reversed_charge) AS max_reversed_charge
    FROM filtered
    GROUP BY cc_call_center_id, cc_zip, t_hour
)
SELECT
    cc_call_center_id,
    cc_zip,
    t_hour,
    return_cnt,
    total_return_amount,
    avg_return_tax,
    min_ship_cost,
    max_reversed_charge,
    SUM(total_return_amount) OVER (
        PARTITION BY cc_call_center_id
        ORDER BY t_hour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_amount
FROM grouped
ORDER BY cc_call_center_id, t_hour
