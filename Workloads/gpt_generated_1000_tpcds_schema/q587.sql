WITH cust_sales AS (
   SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      c.c_birth_country,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      (SELECT SUM(cs2.cs_ext_sales_price) FROM catalog_sales cs2 WHERE cs2.cs_bill_customer_sk = c.c_customer_sk) AS total_sales_scalar
   FROM catalog_sales cs
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   WHERE regexp_like(c.c_birth_country, '^B')
     AND c.c_birth_year BETWEEN 1950 AND 1970
   GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_country
),
store_cust AS (
   SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      c.c_birth_country,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      (SELECT SUM(ss2.ss_ext_sales_price) FROM store_sales ss2 WHERE ss2.ss_customer_sk = c.c_customer_sk) AS total_sales_scalar
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   WHERE c.c_birth_country LIKE '%A'
   GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_country
),
union_all AS (
   SELECT c_customer_sk, c_first_name, c_last_name, c_birth_country, total_sales, total_sales_scalar
   FROM cust_sales
   UNION
   SELECT c_customer_sk, c_first_name, c_last_name, c_birth_country, total_sales, total_sales_scalar
   FROM store_cust
),
intersect_keys AS (
   SELECT cs_bill_customer_sk AS cust_sk FROM catalog_sales
   INTERSECT
   SELECT ss_customer_sk FROM store_sales
),
full_join_promo AS (
   SELECT
      ss.ss_customer_sk,
      ss.ss_ext_sales_price,
      p.p_promo_id,
      p.p_discount_active
   FROM store_sales ss
   FULL OUTER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
)
SELECT
   u.c_customer_sk,
   concat(u.c_first_name, ' ', u.c_last_name) AS full_name,
   substring(u.c_birth_country FROM 1 FOR 3) AS birth_country_prefix,
   u.total_sales,
   u.total_sales_scalar,
   (SELECT COUNT(*) FROM catalog_sales cs3 WHERE cs3.cs_bill_customer_sk = u.c_customer_sk) AS catalog_sales_cnt,
   COALESCE(f.p_promo_id, 'NO_PROMO') AS promo_id,
   f.p_discount_active
FROM union_all u
JOIN intersect_keys i ON u.c_customer_sk = i.cust_sk
LEFT JOIN full_join_promo f ON u.c_customer_sk = f.ss_customer_sk
WHERE regexp_like(u.c_birth_country, '.*[AEIOU].*')
ORDER BY u.total_sales DESC
LIMIT 100
