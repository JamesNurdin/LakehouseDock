WITH return_summary AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_market_manager,
        sm.sm_ship_mode_id,
        sm.sm_code,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(CASE WHEN cr.cr_return_amount > 1000 THEN cr.cr_return_amount ELSE 0 END) AS high_return_amount,
        AVG(cr.cr_return_quantity) AS avg_quantity,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_state = 'CA'
      AND cc.cc_gmt_offset BETWEEN -8.00 AND -5.00
      AND sm.sm_code IN ('AIR', 'SEA')
      AND cd.cd_dep_college_count >= 3
      AND cd.cd_credit_rating = 'A'
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_market_manager,
        sm.sm_ship_mode_id,
        sm.sm_code
)
SELECT
    rs.cc_call_center_id,
    rs.cc_market_manager,
    rs.sm_ship_mode_id,
    rs.sm_code,
    rs.return_cnt,
    rs.total_return_amount,
    rs.high_return_amount,
    rs.avg_quantity,
    rs.distinct_orders,
    CASE
        WHEN rs.total_return_amount > 5000 THEN 'HIGH_TOTAL'
        WHEN rs.return_cnt > 100 THEN 'HIGH_VOLUME'
        ELSE 'NORMAL'
    END AS performance_category
FROM return_summary rs
WHERE rs.return_cnt > 10
  AND rs.total_return_amount > 1000
  AND rs.high_return_amount > 0
  AND rs.distinct_orders >= 5
ORDER BY rs.total_return_amount DESC, rs.cc_call_center_id
LIMIT 100
