WITH cs AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid_inc_ship_tax,
        cc.cc_name,
        sm.sm_type
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_net_paid_inc_ship_tax >= 3000
),
cr AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%damaged%'
),
relevant AS (
    SELECT cs.cs_order_number
    FROM cs
    WHERE EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
          AND cr2.cr_return_amount > 0
    )
    EXCEPT
    SELECT cr_order_number FROM cr
)
SELECT
    cs.cs_order_number,
    cs.cs_net_paid_inc_ship_tax,
    cs.cc_name,
    cs.sm_type
FROM cs
JOIN relevant r ON cs.cs_order_number = r.cs_order_number
ORDER BY cs.cs_net_paid_inc_ship_tax DESC
LIMIT 100
