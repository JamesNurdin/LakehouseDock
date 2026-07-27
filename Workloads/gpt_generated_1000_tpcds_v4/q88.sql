SELECT
    ca_bill.ca_state AS state,
    cd_bill.cd_education_status AS education,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(promo1.p_cost) AS avg_promo_cost,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_cnt
FROM web_sales ws
JOIN customer_demographics cd_bill
  ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
  ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
  ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN promotion promo1
  ON ws.ws_promo_sk = promo1.p_promo_sk
JOIN promotion promo2
  ON ws.ws_promo_sk = promo2.p_promo_sk
JOIN store_returns sr
  ON sr.sr_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship_sr
  ON sr.sr_cdemo_sk = cd_ship_sr.cd_demo_sk
JOIN customer_address ca_ship_sr
  ON sr.sr_addr_sk = ca_ship_sr.ca_address_sk
JOIN customer_address ca_sr
  ON sr.sr_addr_sk = ca_sr.ca_address_sk
GROUP BY ca_bill.ca_state, cd_bill.cd_education_status
ORDER BY total_web_profit DESC
LIMIT 100
