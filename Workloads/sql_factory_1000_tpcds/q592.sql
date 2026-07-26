SELECT
  sca.ca_state AS ship_state,
  bca.ca_state AS bill_state,
  hd_ship.hd_buy_potential AS ship_buy_potential,
  hd_bill.hd_buy_potential AS bill_buy_potential,
  w.w_warehouse_name,
  SUM(ws.ws_net_profit) AS total_net_profit,
  AVG(ws.ws_ext_discount_amt) AS avg_discount_amt,
  SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_list_price), 0) AS profit_margin,
  CASE WHEN SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_list_price), 0) > 0.07 THEN 'High Margin' ELSE 'Low Margin' END AS margin_category,
  RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank_within_warehouse
FROM web_sales ws
JOIN customer_address sca ON ws.ws_ship_addr_sk = sca.ca_address_sk
JOIN customer_address bca ON ws.ws_bill_addr_sk = bca.ca_address_sk
JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
GROUP BY sca.ca_state, bca.ca_state, hd_ship.hd_buy_potential, hd_bill.hd_buy_potential, w.w_warehouse_name
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY w.w_warehouse_name, profit_rank_within_warehouse
