WITH recent_promos AS (
       SELECT p.p_promo_sk,
              p.p_promo_name
       FROM promotion p
       WHERE p.p_start_date_sk >= 2450000 
         AND p.p_end_date_sk <= 2455000
   ),
   catalog_subset AS (
       SELECT cs.cs_bill_customer_sk,
              cs.cs_net_paid_inc_tax,
              cs.cs_item_sk,
              cs.cs_promo_sk
       FROM catalog_sales cs TABLESAMPLE BERNOULLI (10)
       JOIN recent_promos rp ON cs.cs_promo_sk = rp.p_promo_sk
       WHERE cs.cs_bill_customer_sk IN (
                 SELECT c.c_customer_sk
                 FROM customer c
                 WHERE c.c_birth_year BETWEEN 1970 AND 1980
             )
   ),
   store_subset AS (
       SELECT ss.ss_customer_sk,
              ss.ss_net_paid,
              ss.ss_item_sk,
              ss.ss_promo_sk
       FROM store_sales ss
       JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
       WHERE ss.ss_customer_sk IN (
                 SELECT c.c_customer_sk
                 FROM customer c
                 WHERE c.c_birth_year BETWEEN 1970 AND 1980
             )
         AND p.p_discount_active = 'Y'
   )
SELECT combined.customer_id,
       combined.total_spent,
       combined.source
FROM (
        SELECT c.c_customer_id AS customer_id,
               cs.cs_net_paid_inc_tax AS total_spent,
               'catalog' AS source
        FROM catalog_subset cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        UNION
        SELECT c.c_customer_id,
               ss.ss_net_paid,
               'store' AS source
        FROM store_subset ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
     ) AS combined
ORDER BY combined.total_spent DESC
OFFSET 0 LIMIT 100
