SELECT
    cp.cp_department,
    cp.cp_type,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    AVG(d_sales.d_year - c.c_birth_year) AS avg_customer_age_at_first_sale,
    COUNT(DISTINCT c.c_birth_month) AS distinct_birth_months,
    COUNT(DISTINCT ws.web_site_id) AS num_web_sites
FROM catalog_page cp
JOIN date_dim d_start
  ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
  ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN customer c
  ON c.c_first_sales_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
JOIN date_dim d_sales
  ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
JOIN date_dim d_ws
  ON ws.web_open_date_sk = d_ws.d_date_sk
WHERE cp.cp_type = 'monthly'
  AND cp.cp_catalog_number = 3
  AND d_start.d_year = 2022
GROUP BY cp.cp_department, cp.cp_type
HAVING COUNT(DISTINCT c.c_customer_sk) > 5
ORDER BY avg_customer_age_at_first_sale DESC, num_customers ASC
