WITH
  /* Sample a fraction of store sales */
  sampled_store_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
  ),

  /* Distinct customers who bought in store sales */
  ss_customers AS (
    SELECT DISTINCT ss_customer_sk AS cust_sk
    FROM sampled_store_sales
    WHERE ss_net_paid > 0
  ),

  /* Distinct customers who bought in catalog sales */
  cs_customers AS (
    SELECT DISTINCT cs_bill_customer_sk AS cust_sk
    FROM catalog_sales
    WHERE cs_net_paid > 0
  ),

  /* Customers appearing in both store and catalog sales */
  common_customers AS (
    SELECT cust_sk FROM ss_customers
    INTERSECT
    SELECT cust_sk FROM cs_customers
  ),

  /* Customers who bought with a Summer promotion (union of store and catalog) */
  promo_customers AS (
    SELECT ss_customer_sk AS cust_sk
    FROM sampled_store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_promo_name LIKE '%Summer%'
    UNION
    SELECT cs_bill_customer_sk
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_promo_name LIKE '%Summer%'
  ),

  /* Customers who have returned items */
  returned_customers AS (
    SELECT cr_returning_customer_sk AS cust_sk
    FROM catalog_returns
  ),

  /* Customers who bought with the promotion but never returned (EXCEPT) */
  promo_not_returned AS (
    SELECT cust_sk FROM promo_customers
    EXCEPT
    SELECT cust_sk FROM returned_customers
  ),

  /* Final set: customers in common set but not in promo_not_returned (anti‑join) */
  final_customers AS (
    SELECT cust_sk
    FROM common_customers c
    WHERE NOT EXISTS (
      SELECT 1 FROM promo_not_returned pnr WHERE pnr.cust_sk = c.cust_sk
    )
  )
SELECT
  c.c_customer_id,
  concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
  COUNT(*) AS purchase_count,
  SUM(ss.ss_net_paid) AS total_spent,
  regexp_extract(c.c_email_address, '([^@]+)') AS email_user,
  CASE WHEN regexp_like(c.c_email_address, '\\d') THEN 'HasDigit' ELSE 'NoDigit' END AS email_digit_flag
FROM
  sampled_store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN final_customers fc ON fc.cust_sk = c.c_customer_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE
  d.d_year = 2001
  AND c.c_preferred_cust_flag = 'Y'
  AND c.c_email_address LIKE '%@%'
GROUP BY
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  c.c_email_address
ORDER BY
  total_spent DESC
LIMIT 100
