WITH
  date_filtered AS (
    SELECT *
    FROM tpcds.date_dim
    WHERE d_year = 2001
      AND d_weekend = 'N'
      AND d_quarter_name = '2001Q1'
  ),
  call_center_filtered AS (
    SELECT *
    FROM tpcds.call_center TABLESAMPLE BERNOULLI (10)
    WHERE cc_state = 'CA'
      AND cc_employees > 100
      AND cc_gmt_offset BETWEEN -5 AND 5
  ),
  catalog_page_filtered AS (
    SELECT *
    FROM tpcds.catalog_page
    WHERE cp_department = 'Books'
      AND cp_catalog_number IN (5, 12)
      AND cp_type = 'A'
  ),
  catalog_sales_filtered AS (
    SELECT *
    FROM tpcds.catalog_sales
    WHERE cs_quantity > 1
      AND cs_sales_price > 100
      AND cs_coupon_amt = 0
  ),
  catalog_returns_filtered AS (
    SELECT *
    FROM tpcds.catalog_returns
    WHERE cr_refunded_cash > 200
      AND cr_return_amount > 0
      AND cr_return_tax > 0
  ),
  store_sales_filtered AS (
    SELECT *
    FROM tpcds.store_sales
    WHERE ss_quantity > 2
      AND ss_sales_price > 150
      AND ss_net_profit > 0
  ),
  store_returns_filtered AS (
    SELECT *
    FROM tpcds.store_returns
    WHERE sr_return_amt > 100
      AND sr_net_loss > 0
      AND sr_fee = 0
  ),
  web_page_filtered AS (
    SELECT *
    FROM tpcds.web_page
    WHERE wp_type = 'Home'
      AND wp_char_count > 5000
      AND wp_link_count > 10
  ),
  customer_filtered AS (
    SELECT *
    FROM tpcds.customer
    WHERE c_preferred_cust_flag = 'Y'
      AND c_birth_year BETWEEN 1950 AND 1960
      AND c_login IS NOT NULL
  ),
  intersect_customers AS (
    SELECT c.c_customer_sk
    FROM tpcds.store_sales ss
    JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_quantity > 3
    INTERSECT
    SELECT c.c_customer_sk
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_quantity > 2
  )
SELECT
  d.d_date,
  cc.cc_name,
  cp.cp_description,
  cs.cs_order_number,
  cr.cr_returned_date_sk,
  ss.ss_ticket_number,
  sr.sr_returned_date_sk,
  wp.wp_url,
  c.c_customer_id,
  SUM(ss.ss_ext_sales_price) OVER (
    PARTITION BY c.c_customer_sk
    ORDER BY d.d_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cum_store_sales,
  ROW_NUMBER() OVER (
    PARTITION BY c.c_customer_sk
    ORDER BY cs.cs_sold_date_sk DESC
  ) AS rn_cs
FROM date_filtered d
JOIN call_center_filtered cc
  ON cc.cc_open_date_sk = d.d_date_sk
JOIN catalog_page_filtered cp
  ON cp.cp_start_date_sk = d.d_date_sk
JOIN catalog_sales_filtered cs
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_returns_filtered cr
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN store_sales_filtered ss
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store_returns_filtered sr
  ON sr.sr_returned_date_sk = d.d_date_sk
JOIN web_page_filtered wp
  ON wp.wp_creation_date_sk = d.d_date_sk
JOIN customer_filtered c
  ON ss.ss_customer_sk = c.c_customer_sk
WHERE d.d_month_seq BETWEEN 1200 AND 1300
  AND cp.cp_department = 'Books'
  AND cc.cc_company_name = 'CompanyXYZ'
  AND cs.cs_ext_discount_amt < 50
  AND cr.cr_return_quantity <= 5
  AND wp.wp_url LIKE 'http%'
  AND c.c_customer_sk IN (SELECT c_customer_sk FROM intersect_customers)
LIMIT 100
