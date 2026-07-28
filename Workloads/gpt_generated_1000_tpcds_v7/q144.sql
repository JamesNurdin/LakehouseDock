SELECT
    d_ws.d_date AS sales_date,
    p_ws.p_promo_name AS promotion_name,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_returns,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory_qty,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders
FROM web_sales ws
JOIN date_dim d_ws
  ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN time_dim t_ws
  ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN customer c_ws
  ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
JOIN customer_demographics cd_ws
  ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
JOIN customer_address ca_ws
  ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
JOIN ship_mode sm_ws
  ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws
  ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN promotion p_ws
  ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_warehouse_sk = w_ws.w_warehouse_sk
  AND cr.cr_returned_date_sk = d_ws.d_date_sk
LEFT JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm_cr
  ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN inventory inv
  ON inv.inv_date_sk = d_ws.d_date_sk
  AND inv.inv_warehouse_sk = w_ws.w_warehouse_sk
JOIN store_sales ss
  ON ss.ss_promo_sk = p_ws.p_promo_sk
  AND ss.ss_customer_sk = c_ws.c_customer_sk
  AND ss.ss_sold_date_sk = d_ws.d_date_sk
GROUP BY d_ws.d_date, p_ws.p_promo_name
ORDER BY total_web_sales DESC
LIMIT 100
