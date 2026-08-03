WITH unified AS (
    -- First sub‑select: returns shipped by DIAMOND carriers with higher tax rates
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        sm.sm_type,
        w.w_state,
        cr.cr_return_amount
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_tax_percentage > 0.02
      AND sm.sm_carrier = 'DIAMOND'
      AND cr.cr_return_quantity > 5

    UNION ALL

    -- Second sub‑select: returns shipped by GREAT EASTERN carriers with lower tax rates
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        sm.sm_type,
        w.w_state,
        cr.cr_return_amount
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_tax_percentage <= 0.05
      AND sm.sm_carrier = 'GREAT EASTERN'
      AND cr.cr_return_quantity > 3
)
SELECT
    u.cc_name,
    u.sm_type,
    u.w_state,
    SUM(u.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_count,
    CASE WHEN SUM(u.cr_return_amount) > 1000 THEN 'High' ELSE 'Low' END AS amount_category,
    MAX(l.max_return_amount) AS max_return_amount
FROM unified u
LEFT JOIN LATERAL (
    SELECT MAX(cr2.cr_return_amount) AS max_return_amount
    FROM catalog_returns cr2
    WHERE cr2.cr_call_center_sk = u.cc_call_center_sk
) l ON true
GROUP BY ROLLUP (u.cc_name, u.sm_type, u.w_state)
ORDER BY total_return_amount DESC
LIMIT 100
