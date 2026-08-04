WITH sampled_store_sales AS (
       SELECT *
       FROM store_sales TABLESAMPLE BERNOULLI (5)
   ),

   intersect_customers AS (
       SELECT c.c_customer_id,
              c.c_customer_sk
       FROM catalog_sales cs
       JOIN customer c
         ON cs.cs_bill_customer_sk = c.c_customer_sk
       WHERE cs.cs_net_paid_inc_ship_tax > 2000
         AND EXISTS (
               SELECT 1
               FROM ship_mode sm
               WHERE sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
                 AND sm.sm_type = 'EXPRESS'
           )
       INTERSECT
       SELECT c2.c_customer_id,
              c2.c_customer_sk
       FROM sampled_store_sales ss
       JOIN customer c2
         ON ss.ss_customer_sk = c2.c_customer_sk
       WHERE ss.ss_ext_tax > 30
   )
SELECT ic.c_customer_id,
       ic.c_customer_sk,
       (SELECT COUNT(*)
        FROM catalog_sales cs3
        WHERE cs3.cs_bill_customer_sk = ic.c_customer_sk) AS total_catalog_orders,
       'CATALOG' AS source
FROM intersect_customers ic
UNION
SELECT ic.c_customer_id,
       ic.c_customer_sk,
       (SELECT COUNT(*)
        FROM store_sales ss3
        WHERE ss3.ss_customer_sk = ic.c_customer_sk) AS total_store_orders,
       'STORE' AS source
FROM intersect_customers ic
ORDER BY c_customer_id
LIMIT 100
