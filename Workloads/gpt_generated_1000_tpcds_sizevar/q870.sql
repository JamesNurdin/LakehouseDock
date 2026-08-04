WITH sales_agg AS (
   SELECT
       c.c_customer_sk AS c_customer_sk,
       SUM(cs.cs_net_paid_inc_ship) AS total_paid,
       (
           SELECT AVG(cs2.cs_sales_price)
           FROM catalog_sales cs2
           JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
           WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
             AND d2.d_moy = 6
       ) AS avg_price
   FROM catalog_sales cs
   JOIN customer c
     ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN date_dim d
     ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_moy = 6
   GROUP BY c.c_customer_sk
   HAVING SUM(cs.cs_net_paid_inc_ship) > 10000
)

SELECT *
FROM (
   SELECT c_customer_sk, total_paid, avg_price
   FROM sales_agg
   WHERE total_paid > 20000
     AND EXISTS (
        SELECT 1
        FROM inventory i
        JOIN date_dim d_inv ON i.inv_date_sk = d_inv.d_date_sk
        WHERE d_inv.d_moy = 6
          AND i.inv_quantity_on_hand > 5000
     )

   EXCEPT

   SELECT c_customer_sk, total_paid, avg_price
   FROM sales_agg
   WHERE total_paid <= 20000
) AS result
ORDER BY total_paid DESC
OFFSET 10
LIMIT 100
