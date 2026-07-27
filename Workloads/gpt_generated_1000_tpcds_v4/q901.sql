SELECT
    ws.ws_order_number,
    ws.ws_net_paid_inc_ship,
    p.p_promo_name,
    p.p_channel_radio
FROM tpcds.web_sales ws
JOIN tpcds.promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
WHERE p.p_channel_radio = 'N'
  AND ws.ws_net_paid_inc_ship > 1000
ORDER BY ws.ws_net_paid_inc_ship DESC
LIMIT 100
