SELECT
  d.d_date AS event_date,
  d.d_year,
  d.d_month_seq,
  s.s_division_id,
  s.s_store_name,
  wp.wp_type,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(cr.cr_return_quantity) AS total_return_quantity,
  SUM(ws.ws_ext_sales_price) AS total_sales_amount,
  SUM(ws.ws_quantity) AS total_sales_quantity,
  SUM(ws.ws_net_profit) AS total_net_profit,
  COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
  COUNT(DISTINCT ws.ws_order_number) AS distinct_sales_orders,
  AVG(ws.ws_sales_price) AS avg_sales_price,
  (SUM(cr.cr_return_amount) / NULLIF(SUM(ws.ws_ext_sales_price), 0)) AS return_to_sales_ratio
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_ship_date_sk = d.d_date_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
   AND wp.wp_creation_date_sk = d.d_date_sk
   AND wp.wp_access_date_sk = d.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2022
GROUP BY
  d.d_date,
  d.d_year,
  d.d_month_seq,
  s.s_division_id,
  s.s_store_name,
  wp.wp_type
HAVING SUM(cr.cr_return_amount) > 0
ORDER BY total_return_amount DESC
LIMIT 100
