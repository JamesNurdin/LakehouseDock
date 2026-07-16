SELECT d.d_year,
       cp.cp_department,
       SUM(cs.cs_net_paid) AS total_sales,
       COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
       (SELECT SUM(cs2.cs_quantity)
        FROM catalog_sales cs2
        WHERE cs2.cs_sold_date_sk = 2450845) AS total_quantity_on_date
FROM date_dim d
JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cp.cp_type = 'bi-annual'
  AND d.d_year = 1920
GROUP BY d.d_year, cp.cp_department
HAVING SUM(cs.cs_net_paid) > 413.91
