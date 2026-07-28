WITH avg_warehouse AS (
    SELECT cr_warehouse_sk,
           AVG(cr_return_amount) AS avg_return_amount
    FROM catalog_returns
    GROUP BY cr_warehouse_sk
),
filtered AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_warehouse_sk,
        w.w_state,
        w.w_warehouse_name,
        sm.sm_type,
        i.inv_quantity_on_hand,
        cc.cc_employees,
        aw.avg_return_amount
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN avg_warehouse aw ON cr.cr_warehouse_sk = aw.cr_warehouse_sk
    WHERE w.w_state = 'CA'
      AND sm.sm_type IN ('AIR', 'GROUND')
      AND cc.cc_employees > 50
      AND i.inv_quantity_on_hand >= 100
      AND cr.cr_return_amount > 500
      AND EXISTS (
          SELECT 1
          FROM inventory i2
          WHERE i2.inv_warehouse_sk = w.w_warehouse_sk
            AND i2.inv_quantity_on_hand > 200
      )
),
aggregated AS (
    SELECT
        w_state,
        sm_type,
        w_warehouse_name,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_fee) AS total_fee,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(cr_return_amount) > 2000 THEN 'HIGH' ELSE 'LOW' END AS return_category,
        MAX(avg_return_amount) AS avg_return_for_warehouse
    FROM filtered
    GROUP BY ROLLUP (w_state, sm_type, w_warehouse_name)
)
SELECT
    w_state,
    sm_type,
    w_warehouse_name,
    total_return_amount,
    total_fee,
    return_cnt,
    return_category,
    avg_return_for_warehouse,
    RANK() OVER (PARTITION BY w_state ORDER BY total_return_amount DESC) AS state_return_rank
FROM aggregated
WHERE w_state IS NOT NULL
ORDER BY total_return_amount DESC, state_return_rank
LIMIT 100
