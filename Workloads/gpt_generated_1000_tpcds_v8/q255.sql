WITH
  /* Aggregate sales per customer for year 2001 with string filters */
  sales_agg AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      c.c_email_address,
      d.d_year,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      COUNT(*) AS sales_cnt,
      MAX(ss.ss_sold_date_sk) AS latest_sales_date_sk
    FROM store_sales AS ss
    JOIN customer AS c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN date_dim AS d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND c.c_email_address LIKE '%@example.com'
      AND regexp_like(c.c_email_address, '^.*@example\\.com$')
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address, d.d_year
    HAVING SUM(ss.ss_ext_sales_price) > 1000
  ),

  /* Aggregate returns per customer for the same year */
  returns_agg AS (
    SELECT
      c.c_customer_sk,
      SUM(sr.sr_refunded_cash) AS total_refunded,
      COUNT(*) AS return_cnt
    FROM store_returns AS sr
    JOIN customer AS c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN date_dim AS d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND sr.sr_fee > 10
    GROUP BY c.c_customer_sk
  ),

  /* Sets of customer keys */
  customers_with_sales AS (
    SELECT DISTINCT c_customer_sk FROM sales_agg
  ),
  customers_with_returns AS (
    SELECT DISTINCT c_customer_sk FROM returns_agg
  ),
  sales_without_returns AS (
    SELECT c_customer_sk FROM customers_with_sales
    EXCEPT
    SELECT c_customer_sk FROM customers_with_returns
  ),

  /* Scalar sub‑query: average return fee for the year */
  avg_fee AS (
    SELECT AVG(sr.sr_fee) AS avg_fee
    FROM store_returns AS sr
    JOIN date_dim AS d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  )

SELECT
  COALESCE(sa.c_customer_sk, ra.c_customer_sk) AS customer_sk,
  CONCAT(COALESCE(sa.c_first_name, ''), ' ', COALESCE(sa.c_last_name, '')) AS full_name,
  COALESCE(sa.d_year, 2001) AS sales_year,
  sa.total_sales,
  ra.total_refunded,
  (sa.total_sales - COALESCE(ra.total_refunded, 0)) AS net_sales,
  /* Adjust sales by subtracting avg fee * sales count */
  (sa.total_sales - (SELECT avg_fee FROM avg_fee) * COALESCE(sa.sales_cnt, 0)) AS adjusted_sales,
  ROW_NUMBER() OVER (ORDER BY sa.total_sales DESC NULLS LAST) AS sales_rank,
  SUM(sa.total_sales) OVER () AS grand_total_sales
FROM sales_agg AS sa
FULL OUTER JOIN returns_agg AS ra
  ON sa.c_customer_sk = ra.c_customer_sk
WHERE COALESCE(sa.c_customer_sk, ra.c_customer_sk) IN (SELECT c_customer_sk FROM sales_without_returns)
ORDER BY adjusted_sales DESC
