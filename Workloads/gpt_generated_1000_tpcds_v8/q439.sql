WITH
    agg_ship_mode AS (
        SELECT sm_ship_mode_sk,
               sm_ship_mode_id,
               COUNT(*) AS mode_cnt
        FROM ship_mode
        GROUP BY sm_ship_mode_sk, sm_ship_mode_id
    ),
    ws_filtered AS (
        SELECT ws_order_number,
               ws_ship_mode_sk,
               ws_ship_addr_sk,
               ws_bill_addr_sk,
               ws_net_paid_inc_ship,
               ws_quantity,
               ws_sold_date_sk,
               ws_sold_time_sk,
               ws_warehouse_sk
        FROM web_sales
        WHERE ws_sold_date_sk BETWEEN 2451545 AND 2451910
          AND ws_warehouse_sk IN (14, 7)
          AND ws_net_paid_inc_ship > 1000
          AND ws_quantity >= 1
          AND ws_ship_mode_sk IS NOT NULL
          AND ws_bill_addr_sk IS NOT NULL
          AND ws_sold_time_sk IN (49599, 42506)
    ),
    intersect_modes AS (
        SELECT ws_ship_mode_sk FROM web_sales WHERE ws_sold_date_sk BETWEEN 2451545 AND 2451555
        INTERSECT
        SELECT ws_ship_mode_sk FROM web_sales WHERE ws_net_paid_inc_ship > 1500
    ),
    address_modes AS (
        SELECT ca.ca_address_sk,
               array_agg(DISTINCT sm.sm_ship_mode_id) AS mode_ids
        FROM web_sales ws
        JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        GROUP BY ca.ca_address_sk
    )
SELECT
    ca.ca_state,
    sm.sm_ship_mode_id,
    SUM(wf.ws_net_paid_inc_ship) AS total_net_paid,
    AVG(wf.ws_quantity) AS avg_quantity,
    COUNT(DISTINCT wf.ws_order_number) AS distinct_orders,
    MIN(wf.ws_net_paid_inc_ship) AS min_net_paid,
    MAX(wf.ws_net_paid_inc_ship) AS max_net_paid,
    ROW_NUMBER() OVER (PARTITION BY sm.sm_ship_mode_id ORDER BY SUM(wf.ws_net_paid_inc_ship) DESC) AS rn,
    mode_id
FROM ws_filtered wf
RIGHT OUTER JOIN customer_address ca
    ON wf.ws_bill_addr_sk = ca.ca_address_sk
RIGHT OUTER JOIN agg_ship_mode sm
    ON wf.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN address_modes am
    ON ca.ca_address_sk = am.ca_address_sk
LEFT JOIN UNNEST(am.mode_ids) AS t(mode_id) ON TRUE
WHERE EXISTS (
        SELECT 1
        FROM ship_mode sm2
        WHERE sm2.sm_ship_mode_sk = wf.ws_ship_mode_sk
          AND sm2.sm_contract LIKE 'A%'
    )
  AND wf.ws_ship_mode_sk IN (SELECT ws_ship_mode_sk FROM intersect_modes)
GROUP BY ROLLUP (ca.ca_state, sm.sm_ship_mode_id, mode_id)
ORDER BY total_net_paid DESC
LIMIT 100
