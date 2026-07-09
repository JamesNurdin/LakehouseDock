SELECT cp.cp_department,
       d.d_year,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(*) AS return_count,
       (SELECT cp2.cp_description
        FROM catalog_page cp2
        WHERE cp2.cp_type = 'monthly'
        LIMIT 1) AS page_description
FROM catalog_sales cs
INNER JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
INNER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
WHERE cp.cp_type = 'quarterly'
  AND d.d_year = 1904
GROUP BY cp.cp_department, d.d_year
HAVING SUM(cr.cr_return_amount) > 137.72
