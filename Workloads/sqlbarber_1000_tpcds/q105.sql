SELECT cp.cp_department,
       SUM(cs.cs_net_paid) AS total_net_paid
FROM catalog_page cp
JOIN catalog_sales cs
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cp.cp_department = 'DEPARTMENT'
GROUP BY cp.cp_department
