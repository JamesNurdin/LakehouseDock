SELECT
  sold.d_year - (sold.d_year % 5) AS year_5yr_group,
  sold.d_year,
  ship.d_quarter_name,
  sm.sm_type,
  s.s_division_name,
  wp.wp_type,
  CASE
    WHEN date_diff('day', wp_creation.d_date, wp_access.d_date) <= 30 THEN 'Within 30 days'
    WHEN date_diff('day', wp_creation.d_date, wp_access.d_date) <= 90 THEN '30-90 days'
    ELSE 'Over 90 days'
  END AS page_age_bucket,
  COUNT(*) AS order_cnt,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  AVG(ws.ws_net_profit) AS avg_profit,
  SUM(CASE WHEN ws.ws_quantity > 10 THEN ws.ws_ext_sales_price ELSE 0 END) AS sales_qty_gt_10,
  SUM(CASE WHEN ws.ws_quantity <= 10 THEN ws.ws_ext_sales_price ELSE 0 END) AS sales_qty_le_10
FROM web_sales ws
JOIN date_dim AS sold ON ws.ws_sold_date_sk = sold.d_date_sk
JOIN date_dim AS ship ON ws.ws_ship_date_sk = ship.d_date_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s ON s.s_closed_date_sk = ship.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim AS wp_creation ON wp.wp_creation_date_sk = wp_creation.d_date_sk
JOIN date_dim AS wp_access ON wp.wp_access_date_sk = wp_access.d_date_sk
WHERE sold.d_year BETWEEN 2000 AND 2010
  AND sm.sm_type IS NOT NULL
GROUP BY
  sold.d_year - (sold.d_year % 5),
  sold.d_year,
  ship.d_quarter_name,
  sm.sm_type,
  s.s_division_name,
  wp.wp_type,
  CASE
    WHEN date_diff('day', wp_creation.d_date, wp_access.d_date) <= 30 THEN 'Within 30 days'
    WHEN date_diff('day', wp_creation.d_date, wp_access.d_date) <= 90 THEN '30-90 days'
    ELSE 'Over 90 days'
  END
HAVING SUM(ws.ws_ext_sales_price) > 50000
ORDER BY total_sales DESC
LIMIT 100
