/*
Goal: Compute total profit from web sales and catalog sales together with total loss from web returns, broken down by product brand, promotion name, shipping mode type and the hour of the web sale.
The query joins all 14 selected tables, reuses the time_dim table three times (sale time, return time, catalog sale time) and the item table twice (for web and catalog items), resulting in more than nine join clauses, and finally orders by web‑sales profit.
*/
SELECT
  i.i_brand AS brand,
  p.p_promo_name AS promo_name,
  sm.sm_type AS ship_type,
  t_sold.t_hour AS sold_hour,
  SUM(ws.ws_net_profit) AS total_ws_profit,
  SUM(cs.cs_net_profit) AS total_cs_profit,
  SUM(wr.wr_net_loss) AS total_wr_loss,
  COUNT(DISTINCT ws.ws_order_number) AS ws_orders,
  COUNT(DISTINCT cs.cs_order_number) AS cs_orders
FROM web_sales ws
JOIN time_dim t_sold
  ON ws.ws_sold_time_sk = t_sold.t_time_sk
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN customer c
  ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN time_dim t_returned
  ON wr.wr_returned_time_sk = t_returned.t_time_sk
JOIN catalog_sales cs
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN time_dim t_cs
  ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN item i2
  ON cs.cs_item_sk = i2.i_item_sk
GROUP BY
  i.i_brand,
  p.p_promo_name,
  sm.sm_type,
  t_sold.t_hour
ORDER BY total_ws_profit DESC
LIMIT 100
