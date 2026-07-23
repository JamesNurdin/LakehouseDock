SELECT
  d1.d_year AS sale_year,
  ws_site.web_name AS website_name,
  ca_bill.ca_state AS catalog_bill_state,
  ca_ws_bill.ca_state AS web_bill_state,
  SUM(cs.cs_net_profit) AS total_catalog_net_profit,
  SUM(ws.ws_net_profit) AS total_web_net_profit,
  COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
  COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt
FROM catalog_sales cs
JOIN date_dim d1
  ON cs.cs_sold_date_sk = d1.d_date_sk
JOIN date_dim d2
  ON cs.cs_ship_date_sk = d2.d_date_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d1.d_date_sk
JOIN date_dim d4
  ON ws.ws_ship_date_sk = d4.d_date_sk
JOIN customer_address ca_ws_bill
  ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN customer_address ca_ws_ship
  ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN date_dim d5
  ON ws_site.web_open_date_sk = d5.d_date_sk
JOIN date_dim d6
  ON ws_site.web_close_date_sk = d6.d_date_sk
WHERE d1.d_year = 2002
  AND ca_bill.ca_state = 'CA'
  AND ca_ws_bill.ca_state = 'CA'
GROUP BY d1.d_year, ws_site.web_name, ca_bill.ca_state, ca_ws_bill.ca_state
ORDER BY total_catalog_net_profit DESC
LIMIT 100
