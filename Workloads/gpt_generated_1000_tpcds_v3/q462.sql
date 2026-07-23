SELECT cp.cp_catalog_page_number,
       cp.cp_description,
       SUM(cs.cs_net_paid) AS total_net_paid,
       COUNT(*) AS order_count,
       AVG(cs.cs_wholesale_cost) AS avg_wholesale_cost
FROM catalog_sales cs
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cs.cs_wholesale_cost > 50
  AND cp.cp_catalog_page_number = 13
GROUP BY cp.cp_catalog_page_number, cp.cp_description
ORDER BY total_net_paid DESC
LIMIT 100
