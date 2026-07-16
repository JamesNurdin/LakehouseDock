SELECT
  ca_bill.ca_state AS bill_state,
  ca_ship.ca_state AS ship_state,
  hd_bill.hd_buy_potential AS bill_buy_potential,
  hd_ship.hd_buy_potential AS ship_buy_potential,
  COUNT(DISTINCT ws.ws_order_number) AS num_orders,
  SUM(ws.ws_net_profit) AS total_profit,
  AVG(ws.ws_ext_discount_amt) AS avg_discount,
  SUM(ws.ws_quantity) AS total_quantity
FROM web_sales ws
JOIN customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN household_demographics hd_bill
  ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_ship
  ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN household_demographics hd_ship
  ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
  AND ca_bill.ca_country = 'United States'
  AND ca_ship.ca_country = 'United States'
  AND wp.wp_type = 'Content'
  AND hd_bill.hd_buy_potential = 'High'
  AND hd_ship.hd_buy_potential <> 'Low'
GROUP BY ca_bill.ca_state, ca_ship.ca_state, hd_bill.hd_buy_potential, hd_ship.hd_buy_potential
HAVING SUM(ws.ws_net_profit) > 5000
ORDER BY total_profit DESC
LIMIT 100
