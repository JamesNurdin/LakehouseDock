SELECT
  w.w_warehouse_name,
  sca.ca_state AS ship_state,
  hd_ship.hd_vehicle_count,
  SUM(ws.ws_net_profit) AS profit_sum,
  MAX(ws.ws_net_profit) AS max_profit,
  SUM(ws.ws_net_profit) / NULLIF(COUNT(ws.ws_order_number), 0) AS profit_per_order,
  CASE WHEN AVG(ws.ws_ext_discount_amt) < 5 THEN 'Low Discount' ELSE 'High Discount' END AS discount_level,
  DENSE_RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_dense_rank
FROM web_sales ws
JOIN customer_address sca ON ws.ws_ship_addr_sk = sca.ca_address_sk
JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE ws.ws_ship_date_sk BETWEEN 2450000 AND 2450100
GROUP BY w.w_warehouse_name, sca.ca_state, hd_ship.hd_vehicle_count
ORDER BY profit_sum DESC
