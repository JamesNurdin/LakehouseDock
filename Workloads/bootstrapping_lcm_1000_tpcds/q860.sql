SELECT
  s.s_state,
  d_return.d_year,
  d_return.d_quarter_name,
  wp.wp_type,
  COUNT(DISTINCT cr.cr_order_number) AS num_returns,
  SUM(cr.cr_net_loss) AS total_return_loss,
  SUM(cr.cr_return_quantity) AS total_return_quantity,
  AVG(cr.cr_return_amount) AS avg_return_amount,
  COUNT(DISTINCT ws.ws_order_number) AS num_sales,
  SUM(ws.ws_net_paid_inc_ship_tax) AS total_sales_net,
  SUM(ws.ws_ext_sales_price) AS total_sales_ext_price,
  AVG(ws.ws_sales_price) AS avg_sales_price,
  SUM(wp.wp_char_count) AS total_char_count,
  SUM(wp.wp_image_count) AS total_image_count,
  AVG(s.s_tax_percentage) AS avg_store_tax_percentage,
  AVG(s.s_floor_space) AS avg_store_floor_space,
  MAX(d_ship.d_month_seq) AS ship_month_seq,
  MIN(d_wp_creation.d_day_name) AS creation_day_name,
  MAX(d_wp_access.d_day_name) AS access_day_name
FROM catalog_returns cr
JOIN date_dim d_return
  ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d_return.d_date_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
  ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
  ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_return.d_date_sk
WHERE d_return.d_year = 2000
GROUP BY
  s.s_state,
  d_return.d_year,
  d_return.d_quarter_name,
  wp.wp_type
HAVING SUM(ws.ws_net_paid_inc_ship_tax) > 10000
ORDER BY total_sales_net DESC
LIMIT 100
