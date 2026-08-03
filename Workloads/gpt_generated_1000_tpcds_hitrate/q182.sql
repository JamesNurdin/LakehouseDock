WITH ws_agg AS (
    SELECT
        ws.ws_ship_mode_sk,
        ws.ws_ship_cdemo_sk,
        SUM(ws.ws_net_paid) AS total_ws_net_paid,
        COUNT(*) AS ws_order_cnt
    FROM web_sales ws
    GROUP BY ws.ws_ship_mode_sk, ws.ws_ship_cdemo_sk
)
SELECT
    sm.sm_carrier,
    sm.sm_ship_mode_id,
    regexp_extract(sm.sm_ship_mode_id, '(A+)', 1) AS leading_a_seq,
    cd.cd_gender,
    SUM(cr.cr_return_amount) AS total_return_amount,
    ws_agg.total_ws_net_paid,
    ws_agg.ws_order_cnt
FROM catalog_returns cr
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN ws_agg
    ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
    AND ws_agg.ws_ship_cdemo_sk = cd.cd_demo_sk
WHERE regexp_like(sm.sm_ship_mode_id, '^A{5,}')
  AND sm.sm_carrier LIKE 'F%'
  AND cd.cd_marital_status = 'W'
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_call_center_sk = 1
          AND cr2.cr_returned_time_sk = cr.cr_returned_time_sk
    )
GROUP BY
    sm.sm_carrier,
    sm.sm_ship_mode_id,
    regexp_extract(sm.sm_ship_mode_id, '(A+)', 1),
    cd.cd_gender,
    ws_agg.total_ws_net_paid,
    ws_agg.ws_order_cnt
ORDER BY total_return_amount DESC
LIMIT 100
