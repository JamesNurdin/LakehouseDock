SELECT d.d_year,
       cp.cp_department,
       (SELECT cp2.cp_type FROM catalog_page cp2 WHERE cp2.cp_catalog_page_sk = cs.cs_catalog_page_sk) AS page_type,
       SUM(cs.cs_net_paid) AS total_net_paid,
       COUNT(DISTINCT cs.cs_order_number) AS order_cnt
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
WHERE d.d_year = 1911
GROUP BY d.d_year, cp.cp_department, cs.cs_catalog_page_sk
HAVING SUM(cs.cs_net_paid) > 32.76
