SELECT
  s.s_store_id,
  s.s_store_name,
  s.s_city,
  s.s_state,
  d_sales.d_year AS store_closed_year,
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  c.c_email_address,
  hd.hd_vehicle_count,
  hd.hd_buy_potential,
  d_ship.d_year AS ship_year,
  d_ship.d_month_seq AS ship_month_seq,
  d_review.d_year AS review_year,
  wp.wp_web_page_id,
  wp.wp_url,
  d_create.d_date AS page_creation_date,
  d_access.d_date AS page_access_date,
  date_diff('day', d_create.d_date, d_access.d_date) AS days_between_creation_and_access,
  COUNT(DISTINCT wp.wp_web_page_sk) OVER (PARTITION BY c.c_customer_sk) AS total_pages_for_customer,
  ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY d_create.d_date) AS page_seq_for_customer,
  AVG(hd.hd_vehicle_count) OVER (PARTITION BY s.s_store_id) AS avg_vehicle_count_per_store
FROM
  store s
JOIN
  date_dim d_sales
    ON s.s_closed_date_sk = d_sales.d_date_sk
JOIN
  customer c
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN
  household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN
  web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN
  date_dim d_ship
    ON c.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN
  date_dim d_review
    ON c.c_last_review_date = d_review.d_date_sk
JOIN
  date_dim d_create
    ON wp.wp_creation_date_sk = d_create.d_date_sk
JOIN
  date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE
  d_sales.d_current_year = '2022'
ORDER BY
  s.s_store_id,
  c.c_customer_id,
  d_create.d_date
LIMIT 100
