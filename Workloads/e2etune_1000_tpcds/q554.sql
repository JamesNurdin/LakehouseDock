SELECT
  ws_site.web_name,
  sm.sm_ship_mode_id,
  ca.ca_state,
  t.t_hour,
  SUM(ws.ws_net_profit) AS total_profit,
  AVG(ws.ws_ext_discount_amt) AS avg_discount,
  SUM(ws.ws_quantity) AS total_quantity,
  COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
  SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_quantity), 0) AS profit_per_item
FROM web_sales ws
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN time_dim t
  ON ws.ws_sold_time_sk = t.t_time_sk
WHERE ws.ws_sold_date_sk BETWEEN 2450820 AND 2450826
  AND ws.ws_ext_discount_amt > 500
GROUP BY ws_site.web_name, sm.sm_ship_mode_id, ca.ca_state, t.t_hour
HAVING SUM(ws.ws_quantity) > 100
ORDER BY total_profit DESC
LIMIT 50
