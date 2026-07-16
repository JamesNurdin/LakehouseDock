WITH cp_stats AS (
  SELECT
    cp_department,
    cp_type,
    cp_catalog_number,
    COUNT(*) AS num_pages,
    AVG(cp_catalog_page_number) AS avg_page_number,
    MIN(cp_start_date_sk) AS min_start_sk,
    MAX(cp_end_date_sk) AS max_end_sk
  FROM catalog_page
  WHERE cp_department = 'DEPARTMENT'
    AND cp_catalog_number BETWEEN 1 AND 5
    AND cp_start_date_sk >= 2450800
    AND cp_type IS NOT NULL
  GROUP BY cp_department, cp_type, cp_catalog_number
),
cust_stats AS (
  SELECT
    c_birth_month,
    COUNT(*) AS num_customers,
    COUNT(CASE WHEN c_preferred_cust_flag = 'Y' THEN 1 END) AS preferred_customers,
    MIN(c_birth_year) AS min_birth_year,
    MAX(c_birth_year) AS max_birth_year
  FROM customer
  WHERE c_birth_month BETWEEN 1 AND 12
    AND c_preferred_cust_flag IN ('Y', 'N')
  GROUP BY c_birth_month
)
SELECT
  cp.cp_department,
  cp.cp_type,
  cp.cp_catalog_number AS catalog_number,
  cp.num_pages,
  cp.avg_page_number,
  cust.c_birth_month AS birth_month,
  cust.num_customers,
  cust.preferred_customers,
  (cust.num_customers * 1.0 / cp.num_pages) AS customers_per_page,
  ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY cust.num_customers DESC) AS rank_by_customers
FROM cp_stats cp
JOIN cust_stats cust
  ON cp.cp_catalog_number = cust.c_birth_month
WHERE cust.num_customers > 10
ORDER BY cp.cp_department, cust.num_customers DESC
