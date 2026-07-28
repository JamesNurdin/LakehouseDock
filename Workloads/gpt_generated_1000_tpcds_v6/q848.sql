WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
),
ws_detail AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        sm.sm_type AS ship_type,
        wh.w_warehouse_name AS warehouse_name,
        site.web_name
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
)
SELECT
    cs.cs_order_number,
    cs.cs_net_profit,
    sm_cs.sm_type                     AS cs_ship_type,
    wh_cs.w_warehouse_name            AS cs_warehouse,
    ws_detail.ws_order_number         AS ws_order_number,
    ws_detail.ws_net_paid,
    ws_detail.ship_type               AS ws_ship_type,
    ws_detail.warehouse_name          AS ws_warehouse,
    ws_detail.web_name,
    inv_agg.total_qty_on_hand,
    inv_agg2.total_qty_on_hand        AS total_qty_on_hand_cs_warehouse,
    (
        SELECT AVG(ws2.ws_ext_discount_amt)
        FROM web_sales ws2
        WHERE ws2.ws_ship_mode_sk = cs.cs_ship_mode_sk
    )                                 AS avg_discount_for_cs_ship_mode,
    CASE WHEN EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_warehouse_sk = wh_cs.w_warehouse_sk
          AND cs2.cs_net_profit > 5000
    ) THEN 'High' ELSE 'Low' END AS warehouse_profit_category
FROM catalog_sales cs
JOIN ship_mode sm_cs       ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN ship_mode sm_cs_dup   ON cs.cs_ship_mode_sk = sm_cs_dup.sm_ship_mode_sk
JOIN warehouse wh_cs       ON cs.cs_warehouse_sk = wh_cs.w_warehouse_sk
JOIN warehouse wh_cs_dup   ON cs.cs_warehouse_sk = wh_cs_dup.w_warehouse_sk
JOIN ws_detail            ON ws_detail.ws_warehouse_sk = wh_cs.w_warehouse_sk
JOIN ship_mode sm_ws_dup  ON ws_detail.ws_ship_mode_sk = sm_ws_dup.sm_ship_mode_sk
JOIN warehouse wh_ws_dup  ON ws_detail.ws_warehouse_sk = wh_ws_dup.w_warehouse_sk
JOIN inv_agg              ON inv_agg.inv_warehouse_sk = wh_ws_dup.w_warehouse_sk
JOIN inv_agg inv_agg2     ON inv_agg2.inv_warehouse_sk = wh_cs.w_warehouse_sk
ORDER BY cs.cs_net_profit DESC
LIMIT 100
