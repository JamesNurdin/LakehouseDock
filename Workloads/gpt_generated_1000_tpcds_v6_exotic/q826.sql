SELECT
    sm.sm_type,
    sm.sm_carrier,
    p.p_promo_name,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount
FROM tpcds.web_sales ws
JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_type = 'OVERNIGHT'
  AND sm.sm_carrier = 'UPS'
  AND p.p_channel_email = 'Y'
  AND p.p_response_target >= 500
  AND p.p_discount_active = 'Y'
  AND ws.ws_sales_price > 20
  AND ws.ws_quantity >= 2
GROUP BY sm.sm_type, sm.sm_carrier, p.p_promo_name
ORDER BY total_profit DESC
LIMIT 100
