SELECT
  ca.ca_country AS customer_country,
  ca.ca_state AS customer_state,
  CASE
    WHEN customer.c_birth_year < 1970 THEN 'Pre-70'
    WHEN customer.c_birth_year BETWEEN 1970 AND 1989 THEN '70s-80s'
    ELSE '90s+'
  END AS birth_year_group,
  d_sales.d_year AS sales_year,
  d_store_closed.d_year AS store_closed_year,
  d_ship.d_month_seq AS ship_month_seq,
  s.s_market_desc AS store_market,
  COUNT(DISTINCT web_page.wp_web_page_id) AS distinct_page_count,
  SUM(web_page.wp_image_count) AS total_image_count,
  AVG(date_diff('day', d_creation.d_date, d_access.d_date)) AS avg_days_between_creation_and_access,
  SUM(web_page.wp_char_count) AS total_char_count,
  COUNT(DISTINCT s.s_store_id) AS distinct_store_count,
  ROUND(SUM(web_page.wp_image_count) * 1.0 / NULLIF(COUNT(DISTINCT web_page.wp_web_page_id), 0), 2) AS avg_images_per_page
FROM customer
JOIN web_page
  ON web_page.wp_customer_sk = customer.c_customer_sk
JOIN customer_address ca
  ON customer.c_current_addr_sk = ca.ca_address_sk
JOIN date_dim d_ship
  ON customer.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_sales
  ON customer.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_creation
  ON web_page.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
  ON web_page.wp_access_date_sk = d_access.d_date_sk
JOIN store s
  ON true
JOIN date_dim d_store_closed
  ON s.s_closed_date_sk = d_store_closed.d_date_sk
GROUP BY
  ca.ca_country,
  ca.ca_state,
  CASE
    WHEN customer.c_birth_year < 1970 THEN 'Pre-70'
    WHEN customer.c_birth_year BETWEEN 1970 AND 1989 THEN '70s-80s'
    ELSE '90s+'
  END,
  d_sales.d_year,
  d_store_closed.d_year,
  d_ship.d_month_seq,
  s.s_market_desc
HAVING COUNT(DISTINCT web_page.wp_web_page_id) > 0
ORDER BY distinct_page_count DESC
LIMIT 100
