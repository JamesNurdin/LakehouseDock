SELECT
  p.p_promo_name,
  hd_bill.hd_income_band_sk AS bill_income_band,
  hd_ship.hd_income_band_sk AS ship_income_band,
  hd_bill.hd_buy_potential AS bill_buy_potential,
  SUM(ws.ws_net_profit) AS total_net_profit,
  SUM(ws.ws_quantity) AS total_quantity,
  SUM(p.p_cost * ws.ws_quantity) AS total_promo_cost,
  CASE WHEN SUM(p.p_cost * ws.ws_quantity) = 0 THEN NULL
       ELSE SUM(ws.ws_net_profit) / SUM(p.p_cost * ws.ws_quantity)
  END AS profit_to_cost_ratio,
  COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM web_sales ws
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN household_demographics hd_bill
  ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
  ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
WHERE hd_bill.hd_vehicle_count <= 2
  AND hd_ship.hd_vehicle_count <= 2
  AND hd_bill.hd_buy_potential = '1001-5000'
  AND hd_ship.hd_buy_potential = '1001-5000'
  AND p.p_discount_active = 'Y'
  AND p.p_response_target > 0
GROUP BY
  p.p_promo_name,
  hd_bill.hd_income_band_sk,
  hd_ship.hd_income_band_sk,
  hd_bill.hd_buy_potential
HAVING SUM(ws.ws_net_profit) > 1000
   AND SUM(p.p_cost * ws.ws_quantity) > 0
ORDER BY total_net_profit DESC
LIMIT 10
