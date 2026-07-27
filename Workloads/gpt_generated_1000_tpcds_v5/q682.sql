SELECT
  d_sold.d_year,
  wh.w_warehouse_name,
  wsite.web_name,
  ca_bill.ca_state,
  COUNT(DISTINCT ws.ws_order_number) AS order_count,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  AVG(ws.ws_ext_discount_amt) AS avg_discount,
  MIN(ws.ws_ext_ship_cost) AS min_ship_cost,
  MAX(ws.ws_ext_ship_cost) AS max_ship_cost,
  SUM(CASE WHEN r.r_reason_desc = 'Customer Not Satisfied' THEN ws.ws_ext_sales_price ELSE 0 END) AS sales_due_to_dissatisfaction
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
  ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN warehouse wh
  ON ws.ws_warehouse_sk = wh.w_warehouse_sk
JOIN web_returns wr
  ON ws.ws_order_number = wr.wr_order_number
  AND ws.ws_item_sk = wr.wr_item_sk
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
JOIN date_dim d_ret
  ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN customer_address ca_refund
  ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_returning
  ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
JOIN web_page wp_ret
  ON wr.wr_web_page_sk = wp_ret.wp_web_page_sk
WHERE d_sold.d_year = 2001
  AND ca_bill.ca_state = 'CA'
  AND wh.w_warehouse_name = 'Warehouse 1'
  AND wp.wp_type = 'Content'
  AND ws.ws_ext_sales_price > 1000
  AND ws.ws_quantity >= 2
  AND d_ret.d_year = 2001
GROUP BY d_sold.d_year, wh.w_warehouse_name, wsite.web_name, ca_bill.ca_state
ORDER BY total_sales DESC
LIMIT 100
