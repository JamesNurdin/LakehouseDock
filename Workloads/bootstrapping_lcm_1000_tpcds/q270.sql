SELECT
  s.s_store_id,
  s.s_store_name,
  d_sold.d_year,
  d_sold.d_month_seq AS month,
  COUNT(DISTINCT ws.ws_order_number) AS num_orders,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  SUM(ws.ws_net_profit) AS total_profit,
  AVG(ws.ws_coupon_amt) AS avg_coupon_amount,
  AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_shipping_days,
  SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
  AVG(wp.wp_image_count) AS avg_image_count,
  AVG(wp.wp_link_count) AS avg_link_count,
  AVG(date_diff('day', d_page_creation.d_date, d_sold.d_date)) AS avg_days_page_created_to_sale,
  AVG(date_diff('day', d_sold.d_date, d_page_access.d_date)) AS avg_days_sale_to_page_access,
  MIN(d_sold.d_date) AS first_sale_date,
  MAX(d_sold.d_date) AS last_sale_date
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN inventory inv
  ON inv.inv_date_sk = d_sold.d_date_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_page_creation
  ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
JOIN date_dim d_page_access
  ON wp.wp_access_date_sk = d_page_access.d_date_sk
WHERE d_sold.d_year = 2022
GROUP BY
  s.s_store_id,
  s.s_store_name,
  d_sold.d_year,
  d_sold.d_month_seq
ORDER BY total_sales DESC
LIMIT 50
