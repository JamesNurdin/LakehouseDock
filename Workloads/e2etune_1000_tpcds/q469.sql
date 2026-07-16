SELECT p.p_promo_id,
       p.p_promo_name,
       p.p_channel_tv,
       COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
       SUM(ws.ws_ext_discount_amt) AS total_discount,
       SUM(ws.ws_net_profit) AS total_net_profit,
       AVG(ws.ws_net_profit) AS avg_net_profit,
       AVG(hd_ship.hd_vehicle_count) AS avg_ship_vehicle_count,
       RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
FROM web_sales ws
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
WHERE p.p_channel_tv = 'Y'
  AND cd_bill.cd_credit_rating = 'Excellent'
  AND cd_bill.cd_purchase_estimate > 5000
  AND hd_bill.hd_income_band_sk IS NOT NULL
GROUP BY p.p_promo_id, p.p_promo_name, p.p_channel_tv
HAVING COUNT(DISTINCT ws.ws_order_number) >= 10
ORDER BY total_net_profit DESC
LIMIT 5
