WITH
  email_customers AS (
    SELECT c_customer_sk, c_email_address, c_last_name
    FROM customer
    WHERE regexp_like(c_email_address, '^.+@example\\.com$')
      AND c_last_name LIKE 'A%'
  ),
  sales_agg AS (
    SELECT ss.ss_customer_sk,
           d.d_year,
           SUM(ss.ss_net_paid) AS total_paid,
           COUNT(*) AS num_sales,
           CONCAT('Year_', CAST(d.d_year AS VARCHAR)) AS year_label
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_customer_sk, d.d_year
  ),
  returns_agg AS (
    SELECT sr.sr_customer_sk,
           d.d_year,
           SUM(sr.sr_return_amt) AS total_return,
           COUNT(*) AS num_returns
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr.sr_customer_sk, d.d_year
  ),
  full_sales_returns AS (
    SELECT
      COALESCE(s.ss_customer_sk, r.sr_customer_sk) AS customer_sk,
      COALESCE(s.d_year, r.d_year) AS year,
      s.total_paid,
      r.total_return
    FROM (SELECT ss_customer_sk, d_year, total_paid FROM sales_agg) s
    FULL OUTER JOIN (SELECT sr_customer_sk, d_year, total_return FROM returns_agg) r
      ON s.ss_customer_sk = r.sr_customer_sk AND s.d_year = r.d_year
  ),
  email_not_sales AS (
    SELECT c_customer_sk
    FROM email_customers
    EXCEPT
    SELECT ss_customer_sk FROM sales_agg
  ),
  both_sales_and_returns AS (
    SELECT ss_customer_sk AS c_customer_sk
    FROM sales_agg
    INTERSECT
    SELECT sr_customer_sk FROM returns_agg
  ),
  union_keys AS (
    SELECT c_customer_sk FROM email_not_sales
    UNION DISTINCT
    SELECT c_customer_sk FROM both_sales_and_returns
  )
SELECT
  fsr.customer_sk,
  fsr.year,
  COALESCE(fsr.total_paid, 0) AS total_paid,
  COALESCE(fsr.total_return, 0) AS total_return,
  CASE
    WHEN fsr.total_paid IS NOT NULL THEN 'PAID'
    ELSE 'NO_PAID'
  END AS payment_flag,
  regexp_extract(c.c_email_address, '^([^@]+)@', 1) AS email_user,
  SUBSTRING(c.c_last_name, 1, 3) AS last_name_prefix
FROM full_sales_returns fsr
LEFT JOIN customer c ON c.c_customer_sk = fsr.customer_sk
WHERE fsr.customer_sk IN (SELECT c_customer_sk FROM union_keys)
ORDER BY total_paid DESC NULLS LAST
LIMIT 100
