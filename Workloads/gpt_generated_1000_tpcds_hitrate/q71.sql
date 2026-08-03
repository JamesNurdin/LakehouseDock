WITH filtered_customers AS (
  SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.c_salutation,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    regexp_extract(c.c_last_name, '^(.)', 1) AS last_initial
  FROM tpcds.customer c
  WHERE c.c_salutation LIKE 'M%'
    AND regexp_like(c.c_last_name, '^S')
)
SELECT
  fc.c_customer_sk,
  fc.full_name,
  fc.last_initial,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  (
    SELECT COUNT(*)
    FROM tpcds.store_returns sr
    WHERE sr.sr_customer_sk = fc.c_customer_sk
  ) AS total_returns
FROM filtered_customers fc
JOIN tpcds.catalog_sales cs
  ON cs.cs_bill_customer_sk = fc.c_customer_sk
JOIN tpcds.time_dim td
  ON cs.cs_sold_time_sk = td.t_time_sk
WHERE td.t_shift = 'first'
GROUP BY fc.c_customer_sk, fc.full_name, fc.last_initial
ORDER BY total_sales DESC
LIMIT 100
