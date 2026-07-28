WITH high_ship AS (
   SELECT
       cp.cp_department AS department,
       SUM(cs.cs_net_profit) AS total_profit,
       'HighShip' AS segment
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
   WHERE cs.cs_ext_ship_cost > 500
     AND cu.c_email_address LIKE '%@V.com'
   GROUP BY cp.cp_department
),
low_wholesale AS (
   SELECT
       cp.cp_department AS department,
       SUM(cs.cs_net_profit) AS total_profit,
       'LowWholesale' AS segment
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
   WHERE cs.cs_wholesale_cost < 50
     AND cu.c_email_address LIKE '%@V.com'
   GROUP BY cp.cp_department
)
SELECT department, total_profit, segment
FROM high_ship
UNION ALL
SELECT department, total_profit, segment
FROM low_wholesale
ORDER BY department, segment
