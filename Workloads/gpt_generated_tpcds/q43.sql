WITH ws AS (
    SELECT
        ws_ship_mode_sk,
        ws_ext_sales_price,
        ws_ext_discount_amt,
        ws_net_paid,
        ws_net_profit,
        ws_order_number
    FROM web_sales
)
SELECT
    sm.sm_ship_mode_id,
    sm.sm_type,
    sm.sm_carrier,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_ext_discount_amt / NULLIF(ws.ws_ext_sales_price, 0)) AS avg_discount_rate
FROM ws
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_type IS NOT NULL
GROUP BY sm.sm_ship_mode_id, sm.sm_type, sm.sm_carrier
ORDER BY total_sales DESC
LIMIT 10
