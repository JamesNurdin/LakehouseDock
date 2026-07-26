SELECT
  w.w_warehouse_name,
  sca.ca_state AS ship_state,
  COUNT(*) AS sales_count,
  SUM(ws.ws_net_paid_inc_tax) AS total_paid_inc_tax,
  SUM(ws.ws_ext_discount_amt) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS discount_rate,
  CASE WHEN SUM(ws.ws_net_paid_inc_tax) > 500000 THEN 'High Revenue' ELSE 'Low Revenue' END AS revenue_category,
  ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS revenue_rank
FROM web_sales ws
JOIN customer_address sca ON ws.ws_ship_addr_sk = sca.ca_address_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE sca.ca_state IN ('CA', 'NY', 'TX')
GROUP BY w.w_warehouse_name, sca.ca_state
HAVING SUM(ws.ws_net_paid_inc_tax) > 100000
ORDER BY w.w_warehouse_name, revenue_rank
