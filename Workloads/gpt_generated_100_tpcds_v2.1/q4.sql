SELECT cp.cp_catalog_page_id,
       COUNT(*) AS order_count,
       SUM(cs.cs_net_paid) AS total_net_paid
FROM tpcds.catalog_sales cs
JOIN tpcds.catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cp.cp_type = 'monthly'
  AND cs.cs_sales_price > 20.00
GROUP BY cp.cp_catalog_page_id
ORDER BY total_net_paid DESC
LIMIT 100
