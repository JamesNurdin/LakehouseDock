SELECT
  sd.d_year AS sold_year,
  sd.d_month_seq AS sold_month,
  shd.d_year AS ship_year,
  sm.sm_type,
  sm.sm_carrier,
  st.s_state,
  st.s_city,
  wp.wp_type,
  cdd.d_date AS page_creation_date,
  addd.d_date AS page_access_date,
  CASE WHEN sd.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS day_category,
  CASE WHEN sd.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
  FLOOR(ws.ws_quantity / 10.0) AS qty_bin,
  COUNT(DISTINCT ws.ws_order_number) AS num_orders,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  SUM(ws.ws_net_profit) AS total_profit
FROM web_sales ws
JOIN date_dim sd ON ws.ws_sold_date_sk = sd.d_date_sk
JOIN date_dim shd ON ws.ws_ship_date_sk = shd.d_date_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim cdd ON wp.wp_creation_date_sk = cdd.d_date_sk
JOIN date_dim addd ON wp.wp_access_date_sk = addd.d_date_sk
JOIN store st ON st.s_closed_date_sk = sd.d_date_sk
WHERE sd.d_year >= 2000
  AND sm.sm_type IN ('AIR', 'RAIL')
  AND wp.wp_type IS NOT NULL
GROUP BY
  sd.d_year,
  sd.d_month_seq,
  shd.d_year,
  sm.sm_type,
  sm.sm_carrier,
  st.s_state,
  st.s_city,
  wp.wp_type,
  cdd.d_date,
  addd.d_date,
  CASE WHEN sd.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END,
  CASE WHEN sd.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END,
  FLOOR(ws.ws_quantity / 10.0)
HAVING SUM(ws.ws_ext_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 100
