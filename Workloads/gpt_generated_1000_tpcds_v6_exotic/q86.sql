WITH bill_sales AS (
   SELECT
       c.c_salutation,
       SUM(cs.cs_net_paid_inc_tax) AS total_paid,
       CASE WHEN SUM(cs.cs_net_paid_inc_tax) > 5000 THEN 'High' ELSE 'Low' END AS tier,
       'Bill' AS source
   FROM catalog_sales AS cs
   JOIN customer AS c
     ON cs.cs_bill_customer_sk = c.c_customer_sk
   WHERE cs.cs_warehouse_sk = 4
     AND cs.cs_net_paid_inc_tax > 500
   GROUP BY c.c_salutation
),
ship_sales AS (
   SELECT
       c.c_salutation,
       SUM(cs.cs_net_paid_inc_tax) AS total_paid,
       CASE WHEN SUM(cs.cs_net_paid_inc_tax) > 5000 THEN 'High' ELSE 'Low' END AS tier,
       'Ship' AS source
   FROM catalog_sales AS cs
   JOIN customer AS c
     ON cs.cs_ship_customer_sk = c.c_customer_sk
   WHERE cs.cs_warehouse_sk = 6
     AND cs.cs_net_paid_inc_tax > 500
   GROUP BY c.c_salutation
)
SELECT
    combined.c_salutation,
    combined.total_paid,
    combined.tier,
    combined.source
FROM (
    SELECT * FROM bill_sales
    UNION ALL
    SELECT * FROM ship_sales
) AS combined
ORDER BY combined.total_paid DESC
LIMIT 100
