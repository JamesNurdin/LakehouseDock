WITH
  customers_with_catalog AS (
    SELECT cs.cs_bill_customer_sk AS cust_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),
  customers_with_returns AS (
    SELECT cr.cr_refunded_customer_sk AS cust_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),
  eligible_customers AS (
    SELECT cust_sk FROM customers_with_catalog
    EXCEPT
    SELECT cust_sk FROM customers_with_returns
  )
SELECT
  c.c_customer_id,
  concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
  ca.ca_city,
  substring(ca.ca_city, 1, 3) AS city_prefix,
  SUM(ss.ss_net_paid) AS total_net_paid,
  COUNT(*) AS transaction_cnt
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
WHERE d.d_year = 2001
  AND regexp_like(c.c_first_name, '^A')
  AND ca.ca_city LIKE '%Fair%'
  AND ss.ss_customer_sk IN (SELECT cust_sk FROM eligible_customers)
GROUP BY
  c.c_customer_id,
  concat(c.c_first_name, ' ', c.c_last_name),
  ca.ca_city,
  substring(ca.ca_city, 1, 3)
ORDER BY total_net_paid DESC
LIMIT 100
