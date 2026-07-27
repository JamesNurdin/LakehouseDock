WITH catalog_sales_filtered AS (
    SELECT
        cs.cs_order_number      AS order_number,
        cs.cs_item_sk           AS item_sk,
        cs.cs_ship_mode_sk      AS ship_mode_sk,
        cs.cs_net_profit        AS net_profit,
        cs.cs_quantity          AS quantity
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(i.i_item_desc, '(?i).*\\b(box|pack)\\b.*')
      AND sm.sm_carrier LIKE 'D%'
),
web_sales_filtered AS (
    SELECT
        ws.ws_order_number      AS order_number,
        ws.ws_item_sk           AS item_sk,
        ws.ws_ship_mode_sk      AS ship_mode_sk,
        ws.ws_net_profit        AS net_profit,
        ws.ws_quantity          AS quantity
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(i.i_item_desc, '(?i).*\\b(box|pack)\\b.*')
      AND sm.sm_carrier LIKE 'D%'
),
combined_sales AS (
    SELECT * FROM catalog_sales_filtered
    UNION ALL
    SELECT * FROM web_sales_filtered
)
SELECT
    sm.sm_ship_mode_id                              AS ship_mode_id,
    sm.sm_carrier                                   AS carrier,
    COUNT(DISTINCT cs.order_number)                AS distinct_orders,
    SUM(cs.net_profit)                              AS total_profit,
    SUM(cs.quantity)                                AS total_quantity,
    CONCAT('Mode-', sm.sm_ship_mode_id)            AS mode_label,
    REGEXP_EXTRACT(i.i_item_desc, '(?i)(box|pack)', 1) AS matched_term
FROM combined_sales cs
JOIN ship_mode sm ON cs.ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i ON cs.item_sk = i.i_item_sk
GROUP BY
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    i.i_item_desc
HAVING SUM(cs.net_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
