WITH cr_agg AS (
    SELECT
        cr_call_center_sk,
        cr_ship_mode_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_fee) AS total_fee,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450950 AND 2451100
      AND cr_return_quantity > 0
      AND cr_fee > 5
      AND cr_return_amount > 0
      AND cr_refunded_cash < 5000
      AND cr_net_loss IS NOT NULL
    GROUP BY cr_call_center_sk, cr_ship_mode_sk
),
air_returns AS (
    SELECT
        cc.cc_division_name AS division_name,
        sm.sm_ship_mode_id AS ship_mode_id,
        cr.total_return_amount,
        cr.total_fee,
        cr.return_cnt
    FROM cr_agg cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type = 'AIR'
      AND cc.cc_state = 'CA'
      AND cc.cc_employees > 500000
      AND cc.cc_rec_start_date >= DATE '1998-01-01'
      AND cc.cc_rec_end_date <= DATE '2000-12-31'
),
sea_returns AS (
    SELECT
        cc.cc_division_name AS division_name,
        sm.sm_ship_mode_id AS ship_mode_id,
        cr.total_return_amount,
        cr.total_fee,
        cr.return_cnt
    FROM cr_agg cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type = 'SEA'
      AND cc.cc_state = 'NY'
      AND cc.cc_employees > 500000
      AND cc.cc_rec_start_date >= DATE '1998-01-01'
      AND cc.cc_rec_end_date <= DATE '2000-12-31'
),
combined AS (
    SELECT * FROM air_returns
    UNION ALL
    SELECT * FROM sea_returns
)
SELECT
    division_name,
    COUNT(*) AS rows_per_division,
    SUM(total_return_amount) AS sum_return_amount,
    AVG(total_fee) AS avg_fee,
    SUM(return_cnt) AS total_return_cnt
FROM combined
GROUP BY division_name
HAVING SUM(total_return_amount) > 10000
ORDER BY sum_return_amount DESC
LIMIT 100
