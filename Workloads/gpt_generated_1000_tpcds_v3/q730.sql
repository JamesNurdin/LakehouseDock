SELECT
  s.s_store_name,
  d_sold.d_year,
  p.p_promo_name,
  SUM(ws.ws_net_profit) AS total_net_profit,
  SUM(CASE WHEN p.p_discount_active = 'Y' THEN ws.ws_net_profit ELSE 0 END) AS profit_when_discount_active,
  SUM(wr.wr_return_amt) AS total_return_amount,
  COUNT(DISTINCT ws.ws_order_number) AS order_count
FROM tpcds.web_sales ws
JOIN tpcds.date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.time_dim t_sold
  ON ws.ws_sold_time_sk = t_sold.t_time_sk
JOIN tpcds.customer c_bill
  ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN tpcds.customer_demographics cd_bill
  ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN tpcds.customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.customer c_ship
  ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN tpcds.customer_demographics cd_ship
  ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN tpcds.customer_address ca_ship
  ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN tpcds.warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_site site
  ON ws.ws_web_site_sk = site.web_site_sk
JOIN tpcds.date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN tpcds.web_returns wr
  ON ws.ws_order_number = wr.wr_order_number
JOIN tpcds.reason r
  ON wr.wr_reason_sk = r.r_reason_sk
JOIN tpcds.date_dim d_return
  ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN tpcds.time_dim t_return
  ON wr.wr_returned_time_sk = t_return.t_time_sk
JOIN tpcds.store s
  ON s.s_closed_date_sk = d_return.d_date_sk
WHERE d_sold.d_year = 2001
GROUP BY s.s_store_name, d_sold.d_year, p.p_promo_name
ORDER BY total_net_profit DESC, order_count DESC
LIMIT 100
