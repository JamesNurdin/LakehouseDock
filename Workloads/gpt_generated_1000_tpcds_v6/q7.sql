/*
Goal: Identify top warehouses (by total net profit) whose names contain 'National' or 'Local', have zip codes starting with '64', and have at least one order whose order number matches the pattern ^1[3-9]$ (i.e., 13‑19). The query demonstrates string processing with REGEXP_LIKE, REGEXP_EXTRACT, LIKE, CONCAT, SUBSTRING, and uses a subquery in an EXISTS clause, plus aggregation and ordering.
*/
WITH ws_agg AS (
    SELECT
        ws.ws_warehouse_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS order_cnt,
        AVG(ws.ws_quantity) AS avg_quantity
    FROM web_sales ws
    WHERE ws.ws_ship_mode_sk IN (5, 10, 13)
    GROUP BY ws.ws_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    REGEXP_EXTRACT(w.w_warehouse_name, '(National|Local)', 1) AS matched_name_part,
    CONCAT(SUBSTRING(w.w_warehouse_name, 1, 5), '_', w.w_city) AS warehouse_label,
    w.w_zip,
    ws_agg.total_net_profit,
    ws_agg.order_cnt,
    ws_agg.avg_quantity
FROM warehouse w
JOIN ws_agg
    ON w.w_warehouse_sk = ws_agg.ws_warehouse_sk
WHERE
    REGEXP_LIKE(w.w_warehouse_name, '(National|Local)')
    AND w.w_zip LIKE '64%'
    AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_warehouse_sk = w.w_warehouse_sk
          AND REGEXP_LIKE(CAST(ws2.ws_order_number AS VARCHAR), '^1[3-9]$')
    )
ORDER BY ws_agg.total_net_profit DESC
LIMIT 100
