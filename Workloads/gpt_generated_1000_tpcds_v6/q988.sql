WITH ws_detail AS (
    SELECT
        ws.ws_order_number,
        ws.ws_warehouse_sk,
        ws.ws_ship_mode_sk,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_wholesale_cost,
        ws.ws_quantity
    FROM web_sales ws
    WHERE ws.ws_wholesale_cost > 30
      AND ws.ws_ship_addr_sk IN (921176, 5324750, 458242)
      AND ws.ws_net_paid > 0
)
SELECT
    w.w_warehouse_name,
    sm.sm_code,
    COUNT(DISTINCT ws_detail.ws_order_number) AS distinct_orders,
    SUM(ws_detail.ws_net_profit) AS total_profit,
    AVG(ws_detail.ws_net_profit) AS avg_profit,
    SUM(ws_detail.ws_ext_sales_price) AS total_sales,
    CASE
        WHEN SUM(ws_detail.ws_net_profit) > 100000 THEN 'HIGH'
        WHEN SUM(ws_detail.ws_net_profit) > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category
FROM ws_detail
JOIN ship_mode sm
    ON ws_detail.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON ws_detail.ws_warehouse_sk = w.w_warehouse_sk
WHERE sm.sm_code IN ('AIR', 'SEA')
  AND w.w_county = 'Fairfield County'
  AND EXISTS (
        SELECT 1
        FROM ship_mode sm2
        WHERE sm2.sm_contract = 'Ek'
          AND sm2.sm_ship_mode_sk = ws_detail.ws_ship_mode_sk
    )
GROUP BY w.w_warehouse_name, sm.sm_code
ORDER BY total_profit DESC
LIMIT 100
