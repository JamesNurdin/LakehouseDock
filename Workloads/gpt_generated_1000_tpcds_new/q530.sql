WITH base_customers AS (
   SELECT c.c_customer_sk,
          c.c_customer_id,
          concat(c.c_salutation, ' ', c.c_last_name) AS full_name,
          c.c_first_sales_date_sk
   FROM tpcds.customer c
   JOIN tpcds.date_dim d
     ON c.c_first_sales_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND regexp_like(c.c_customer_id, '^AAAA')
     AND c.c_salutation LIKE 'Mr%'
),
expanded_chars AS (
   SELECT bc.c_customer_id,
          ch
   FROM base_customers bc
   CROSS JOIN UNNEST(regexp_extract_all(bc.c_customer_id, '(.)')) AS t(ch)
),
union_ids AS (
   SELECT c.c_customer_id
   FROM base_customers c
   WHERE c.c_customer_id LIKE '%DDAA'
   UNION
   SELECT CAST(cr.cr_refunded_customer_sk AS varchar) AS c_customer_id
   FROM tpcds.catalog_returns cr
   JOIN tpcds.date_dim d
     ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
except_ids AS (
   SELECT c.c_customer_id
   FROM base_customers c
   EXCEPT
   SELECT CAST(cr.cr_refunded_customer_sk AS varchar)
   FROM tpcds.catalog_returns cr
   JOIN tpcds.date_dim d
     ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
)
SELECT
   bc.c_customer_id,
   bc.full_name,
   COUNT(DISTINCT ec.ch) AS distinct_char_cnt,
   SUM(cs.cs_net_paid) AS total_net_paid,
   MIN(d.d_date) AS first_sale_date
FROM base_customers bc
JOIN tpcds.catalog_sales cs
  ON bc.c_customer_sk = cs.cs_bill_customer_sk
JOIN tpcds.date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN expanded_chars ec
  ON bc.c_customer_id = ec.c_customer_id
WHERE bc.c_customer_id IN (SELECT c_customer_id FROM union_ids)
  AND bc.c_customer_id NOT IN (SELECT c_customer_id FROM except_ids)
GROUP BY bc.c_customer_id, bc.full_name
ORDER BY total_net_paid DESC
OFFSET 0 LIMIT 20
