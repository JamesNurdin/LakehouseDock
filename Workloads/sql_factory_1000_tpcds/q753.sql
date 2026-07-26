SELECT
  bca.ca_state AS bill_state,
  hd_bill.hd_buy_potential,
  w.w_warehouse_name,
  SUM(ws.ws_ext_ship_cost) AS total_ship_cost,
  AVG(ws.ws_ext_tax) AS avg_tax,
  SUM(ws.ws_ext_ship_cost) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS shipping_cost_ratio,
  CASE WHEN SUM(ws.ws_ext_ship_cost) > 200000 THEN 'Expensive Shipping' ELSE 'Affordable Shipping' END AS shipping_category,
  RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY SUM(ws.ws_ext_ship_cost) DESC) AS ship_cost_rank
FROM web_sales ws
JOIN customer_address bca ON ws.ws_bill_addr_sk = bca.ca_address_sk
JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE ws.ws_quantity >= 5
GROUP BY bca.ca_state, hd_bill.hd_buy_potential, w.w_warehouse_name
HAVING SUM(ws.ws_ext_ship_cost) > 0
ORDER BY ship_cost_rank DESC
