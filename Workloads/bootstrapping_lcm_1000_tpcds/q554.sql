SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_return.d_year AS return_year,
    d_return.d_quarter_name AS return_quarter,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_return_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    ROUND(AVG(wr.wr_fee), 2) AS avg_fee,
    SUM(wr.wr_return_quantity) AS total_return_quantity,
    COUNT(DISTINCT c_refunded.c_customer_id) AS distinct_refunded_customers,
    COUNT(DISTINCT c_returning.c_customer_id) AS distinct_returning_customers,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    SUM(CASE WHEN wp.wp_type = 'Landing' THEN 1 ELSE 0 END) AS landing_page_returns,
    SUM(CASE WHEN wp.wp_type = 'Product' THEN 1 ELSE 0 END) AS product_page_returns,
    SUM(CASE WHEN wp.wp_type = 'Search' THEN 1 ELSE 0 END) AS search_page_returns,
    MIN(d_return.d_date) AS first_return_date,
    MAX(d_return.d_date) AS last_return_date,
    c_refunded.c_first_name AS refunded_customer_first_name,
    c_refunded.c_last_name AS refunded_customer_last_name,
    c_refunded.c_email_address AS refunded_customer_email,
    c_page_owner.c_first_name AS page_owner_first_name,
    c_page_owner.c_last_name AS page_owner_last_name,
    d_customer_first_sales.d_year AS customer_first_sales_year,
    d_customer_first_shipto.d_year AS customer_first_shipto_year,
    d_web_creation.d_year AS web_page_creation_year,
    d_web_access.d_year AS web_page_access_year
FROM web_returns wr
JOIN date_dim d_return
  ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_return.d_date_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN customer c_refunded
  ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer c_returning
  ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
JOIN customer c_page_owner
  ON wp.wp_customer_sk = c_page_owner.c_customer_sk
JOIN date_dim d_customer_first_shipto
  ON c_refunded.c_first_shipto_date_sk = d_customer_first_shipto.d_date_sk
JOIN date_dim d_customer_first_sales
  ON c_refunded.c_first_sales_date_sk = d_customer_first_sales.d_date_sk
JOIN date_dim d_web_creation
  ON wp.wp_creation_date_sk = d_web_creation.d_date_sk
JOIN date_dim d_web_access
  ON wp.wp_access_date_sk = d_web_access.d_date_sk
WHERE d_return.d_year BETWEEN 2015 AND 2022
  AND s.s_state = 'CA'
  AND wp.wp_type IN ('Landing', 'Product', 'Search')
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_return.d_year,
    d_return.d_quarter_name,
    c_refunded.c_first_name,
    c_refunded.c_last_name,
    c_refunded.c_email_address,
    c_page_owner.c_first_name,
    c_page_owner.c_last_name,
    d_customer_first_sales.d_year,
    d_customer_first_shipto.d_year,
    d_web_creation.d_year,
    d_web_access.d_year
HAVING SUM(wr.wr_return_amt) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
