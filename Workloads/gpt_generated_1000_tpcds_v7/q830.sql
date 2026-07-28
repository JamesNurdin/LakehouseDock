WITH dhl_sales AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        sm.sm_carrier,
        SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_carrier = 'DHL'
      AND cs.cs_ext_ship_cost > 500
    GROUP BY cc.cc_call_center_id, cc.cc_name, sm.sm_carrier
),
airborne_sales AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        sm.sm_carrier,
        SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_carrier = 'AIRBORNE'
      AND cs.cs_ext_ship_cost <= 500
    GROUP BY cc.cc_call_center_id, cc.cc_name, sm.sm_carrier
)
SELECT
    cc_call_center_id,
    cc_name,
    sm_carrier,
    total_ship_cost,
    order_cnt
FROM dhl_sales
UNION ALL
SELECT
    cc_call_center_id,
    cc_name,
    sm_carrier,
    total_ship_cost,
    order_cnt
FROM airborne_sales
ORDER BY total_ship_cost DESC
LIMIT 100
