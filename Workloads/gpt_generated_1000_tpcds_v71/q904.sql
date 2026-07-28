WITH sales_summary AS (
    SELECT
        cc.cc_call_center_id AS call_center_id,
        sm.sm_type AS ship_mode_type,
        'sales' AS metric,
        SUM(cs.cs_net_profit) AS amount
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cc.cc_rec_end_date = DATE '2001-12-31'
      AND sm.sm_type = 'AIR'
    GROUP BY cc.cc_call_center_id, sm.sm_type
),
returns_summary AS (
    SELECT
        cc.cc_call_center_id AS call_center_id,
        sm.sm_type AS ship_mode_type,
        'returns' AS metric,
        SUM(cr.cr_net_loss) AS amount
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cc.cc_rec_end_date = DATE '2001-12-31'
      AND sm.sm_type = 'GROUND'
      AND cr.cr_return_amount > 100
    GROUP BY cc.cc_call_center_id, sm.sm_type
)
SELECT *
FROM sales_summary
UNION ALL
SELECT *
FROM returns_summary
ORDER BY amount DESC
LIMIT 100
