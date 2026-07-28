WITH cs_agg AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_order_number,
        SUM(cs.cs_net_paid) AS sum_net_paid,
        SUM(cs.cs_ext_wholesale_cost) AS sum_wholesale_cost,
        COUNT(*) AS cnt_sales,
        AVG(cs.cs_quantity) AS avg_quantity
    FROM catalog_sales cs
    WHERE cs.cs_ext_wholesale_cost > 1000
      AND cs.cs_quantity BETWEEN 1 AND 10
      AND cs.cs_ship_mode_sk IN (4, 8)
    GROUP BY cs.cs_call_center_sk, cs.cs_ship_mode_sk, cs.cs_warehouse_sk, cs.cs_order_number
),
ws_agg AS (
    SELECT
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        SUM(ws.ws_net_paid) AS sum_ws_net_paid,
        AVG(ws.ws_quantity) AS avg_ws_quantity,
        COUNT(*) AS cnt_ws
    FROM web_sales ws
    WHERE ws.ws_quantity < 5
      AND ws.ws_ship_mode_sk IN (4, 8)
    GROUP BY ws.ws_ship_mode_sk, ws.ws_warehouse_sk
)
SELECT
    cc.cc_name,
    sm.sm_carrier,
    w.w_state,
    agg.sum_net_paid,
    agg.sum_wholesale_cost,
    agg.cnt_sales,
    COALESCE(cr.cr_return_amount, 0) AS return_amount,
    ws_agg.sum_ws_net_paid,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_name ORDER BY agg.sum_net_paid DESC) AS rn
FROM cs_agg agg
JOIN call_center cc
    ON agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON agg.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = agg.cs_order_number
   AND cr.cr_call_center_sk = cc.cc_call_center_sk
   AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   AND cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN ws_agg
    ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
   AND ws_agg.ws_warehouse_sk = w.w_warehouse_sk
WHERE
    sm.sm_carrier = 'UPS'
  AND sm.sm_contract = '5FKNB0j8aaqTB'
  AND w.w_street_type = 'Street'
  AND w.w_suite_number = 'Suite 480'
  AND cc.cc_state = 'CA'
  AND agg.sum_wholesale_cost > 5000
ORDER BY agg.sum_net_paid DESC
LIMIT 100
