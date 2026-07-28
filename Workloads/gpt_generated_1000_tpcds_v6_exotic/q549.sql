SELECT
    i.i_category AS category,
    d_cs.d_year AS year,
    p.p_promo_name AS promo_name,
    sm.sm_type AS ship_type,
    ca_cs.ca_state AS state,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    SUM(cs.cs_ext_sales_price) AS catalog_sales,
    SUM(ss.ss_ext_sales_price) AS store_sales,
    SUM(ws.ws_ext_sales_price) AS web_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    (SUM(cs.cs_ext_sales_price) + SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) - SUM(sr.sr_return_amt)) AS net_sales,
    (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss)) AS net_profit,
    SUM(cs.cs_quantity + ss.ss_quantity + ws.ws_quantity) AS total_quantity
FROM catalog_sales cs
JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN customer_address ca_cs ON cs.cs_bill_addr_sk = ca_cs.ca_address_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk

JOIN store_sales ss
  ON ss.ss_item_sk = i.i_item_sk
 AND ss.ss_sold_date_sk = d_cs.d_date_sk
 AND ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk

JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
 AND sr.sr_item_sk = ss.ss_item_sk
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk

JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
 AND ws.ws_sold_date_sk = d_cs.d_date_sk
 AND ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk

WHERE d_cs.d_year = 2001
  AND d_ss.d_year = 2001
  AND t_cs.t_hour = 14
  AND i.i_category = 'Sports'
  AND p.p_discount_active = 'Y'
  AND sm.sm_type = 'AIR'
  AND ca_cs.ca_state = 'TX'
  AND cs.cs_net_paid_inc_ship_tax > 5000

GROUP BY i.i_category, d_cs.d_year, p.p_promo_name, sm.sm_type, ca_cs.ca_state

HAVING (SUM(cs.cs_ext_sales_price) + SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) - SUM(sr.sr_return_amt)) > 10000

ORDER BY net_sales DESC

LIMIT 100
