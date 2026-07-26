SELECT
  bca.ca_state AS bill_state,
  w.w_warehouse_name,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  SUM(ws.ws_ext_discount_amt) AS total_discount,
  (SUM(ws.ws_ext_sales_price) - SUM(ws.ws_ext_discount_amt)) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS effective_margin,
  CASE WHEN (SUM(ws.ws_ext_sales_price) - SUM(ws.ws_ext_discount_amt)) / NULLIF(SUM(ws.ws_ext_sales_price), 0) > 0.15 THEN 'Strong Margin' ELSE 'Weak Margin' END AS margin_strength,
  ROW_NUMBER() OVER (ORDER BY (SUM(ws.ws_ext_sales_price) - SUM(ws.ws_ext_discount_amt)) DESC) AS overall_margin_rank
FROM web_sales ws
JOIN customer_address bca ON ws.ws_bill_addr_sk = bca.ca_address_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE w.w_state = 'CA' AND ws.ws_net_profit <> 0
GROUP BY bca.ca_state, w.w_warehouse_name
HAVING SUM(ws.ws_ext_sales_price) > 1000000
ORDER BY overall_margin_rank
