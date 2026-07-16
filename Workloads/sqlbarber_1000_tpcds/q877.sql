SELECT cp.cp_department,
       d.d_month_seq,
       SUM(cs.cs_net_paid) AS total_net_paid,
       AVG(cs.cs_quantity) AS avg_quantity
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE d.d_year = 1903 AND cp.cp_type = 'monthly'
GROUP BY cp.cp_department, d.d_month_seq
