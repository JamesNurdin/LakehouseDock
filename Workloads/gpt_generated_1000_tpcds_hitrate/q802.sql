SELECT p.p_promo_name,
       ws.ws_order_number,
       ws.ws_net_paid_inc_ship
FROM tpcds.promotion AS p
JOIN tpcds.web_sales AS ws
  ON ws.ws_promo_sk = p.p_promo_sk
WHERE p.p_channel_catalog = 'N'
  AND ws.ws_ship_date_sk = 2451411
