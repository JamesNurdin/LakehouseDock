WITH first_part AS (
   SELECT
       c.c_customer_sk,
       concat(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
       i.i_category,
       sum(ss.ss_net_paid_inc_tax) AS total_spent,
       count(*) AS txn_count,
       pw.first_word
   FROM store_sales ss
   FULL OUTER JOIN item i
       ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c
       ON ss.ss_customer_sk = c.c_customer_sk
   LEFT JOIN LATERAL (
       SELECT regexp_extract(i.i_product_name, '^(\\w+)', 1) AS first_word
   ) pw ON true
   WHERE i.i_category LIKE '%Tools%'
     AND regexp_like(c.c_first_name, '^[A-M].*')
   GROUP BY c.c_customer_sk,
            concat(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name),
            i.i_category,
            pw.first_word
),
second_part AS (
   SELECT
       c.c_customer_sk,
       concat(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
       i.i_category,
       sum(ss.ss_net_paid_inc_tax) AS total_spent,
       count(*) AS txn_count,
       pw.first_word
   FROM store_sales ss
   JOIN item i
       ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c
       ON ss.ss_customer_sk = c.c_customer_sk
   LEFT JOIN LATERAL (
       SELECT regexp_extract(i.i_product_name, '^(\\w+)', 1) AS first_word
   ) pw ON true
   WHERE EXISTS (
       SELECT 1 FROM store_sales ss2
       WHERE ss2.ss_customer_sk = c.c_customer_sk
         AND ss2.ss_net_paid_inc_tax > 2000
   )
   GROUP BY c.c_customer_sk,
            concat(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name),
            i.i_category,
            pw.first_word
)
SELECT *
FROM first_part
UNION
SELECT *
FROM second_part
ORDER BY total_spent DESC
LIMIT 100
