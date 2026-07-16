SELECT
  d_return.d_year AS return_year,
  CASE
    WHEN d_return.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
    WHEN d_return.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
    WHEN d_return.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
    ELSE 'Q4'
  END AS return_quarter,
  s.s_state,
  s.s_city,
  wp.wp_type,
  COUNT(DISTINCT ss.ss_ticket_number) AS tickets_sold,
  SUM(ss.ss_quantity) AS total_quantity,
  SUM(ss.ss_ext_sales_price) AS total_sales_amount,
  SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
  SUM(ss.ss_net_profit) AS total_net_profit,
  SUM(wr.wr_return_amt) AS total_return_amount,
  SUM(wr.wr_return_quantity) AS total_return_qty,
  AVG(wp.wp_image_count) AS avg_image_count,
  AVG(wp.wp_link_count) AS avg_link_count,
  CASE
    WHEN SUM(ss.ss_ext_sales_price) > 0 THEN SUM(wr.wr_return_amt) / SUM(ss.ss_ext_sales_price)
    ELSE NULL
  END AS return_to_sales_ratio,
  CASE
    WHEN SUM(ss.ss_ext_sales_price) > 0 THEN SUM(ss.ss_net_profit) / SUM(ss.ss_ext_sales_price)
    ELSE NULL
  END AS profit_margin,
  SUM(CASE WHEN d_closed.d_date_sk IS NOT NULL THEN 1 ELSE 0 END) AS closed_date_count
FROM web_page wp
JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN web_returns wr ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN store_sales ss ON ss.ss_sold_date_sk = d_return.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d_return.d_year = 2022
GROUP BY
  d_return.d_year,
  CASE
    WHEN d_return.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
    WHEN d_return.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
    WHEN d_return.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
    ELSE 'Q4'
  END,
  s.s_state,
  s.s_city,
  wp.wp_type
ORDER BY total_sales_amount DESC
LIMIT 100
