SELECT
  ca_bill.ca_county,
  COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
  SUM(ws.ws_net_paid) AS total_net_paid,
  AVG(ws.ws_sales_price) AS avg_sales_price,
  REGEXP_EXTRACT(ca_ship.ca_suite_number, '(\\d+)$') AS ship_suite_suffix
FROM tpcds.web_sales ws
JOIN tpcds.customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.customer_address ca_ship
  ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
WHERE ca_bill.ca_street_name LIKE '%Lincoln%'
  AND REGEXP_LIKE(ca_ship.ca_suite_number, 'Suite \\d+$')
  AND ws.ws_sales_price > 50
GROUP BY
  ca_bill.ca_county,
  REGEXP_EXTRACT(ca_ship.ca_suite_number, '(\\d+)$')
ORDER BY total_net_paid DESC
LIMIT 100
