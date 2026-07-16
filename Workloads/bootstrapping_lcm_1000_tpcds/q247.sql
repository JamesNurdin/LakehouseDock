SELECT
  s.s_store_id,
  s.s_store_name,
  d_ret.d_year AS return_year,
  d_ret.d_month_seq AS return_month,
  COUNT(*) AS total_returns,
  SUM(sr.sr_return_amt) AS total_return_amount,
  SUM(sr.sr_net_loss) AS total_net_loss,
  AVG(sr.sr_net_loss) AS avg_net_loss,
  COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
  COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages_created,
  MIN(d_page_creation.d_date) AS earliest_page_creation_date,
  MAX(d_page_access.d_date) AS latest_page_access_date,
  MIN(d_first_shipto.d_date) AS earliest_customer_ship_date,
  MAX(d_last_review.d_date) AS latest_customer_review_date,
  AVG(DATE_DIFF('day', d_store_closed.d_date, d_ret.d_date)) AS avg_days_since_store_closed
FROM store_returns sr
JOIN date_dim d_ret
  ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
  ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN customer c
  ON sr.sr_customer_sk = c.c_customer_sk
JOIN date_dim d_first_shipto
  ON c.c_first_shipto_date_sk = d_first_shipto.d_date_sk
JOIN date_dim d_first_sales
  ON c.c_first_sales_date_sk = d_first_sales.d_date_sk
JOIN date_dim d_last_review
  ON c.c_last_review_date = d_last_review.d_date_sk
JOIN web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_page_creation
  ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
JOIN date_dim d_page_access
  ON wp.wp_access_date_sk = d_page_access.d_date_sk
WHERE d_ret.d_year >= 2015
  AND s.s_market_desc = 'Online'
GROUP BY
  s.s_store_id,
  s.s_store_name,
  d_ret.d_year,
  d_ret.d_month_seq
ORDER BY total_net_loss DESC
LIMIT 100
