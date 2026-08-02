SELECT cp.cp_type,
       COUNT(*) AS order_count,
       SUM(cs.cs_net_paid) AS total_net_paid,
       AVG(cs.cs_net_paid) AS avg_net_paid
FROM catalog_page cp
JOIN catalog_sales cs
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cp.cp_type = 'monthly'
  AND cs.cs_quantity > 30
GROUP BY cp.cp_type
ORDER BY total_net_paid DESC
LIMIT 100
