SELECT
    cp.cp_catalog_page_id,
    cp.cp_type,
    cp.cp_department,
    sd.d_year AS start_year,
    ed.d_year AS end_year,
    cd.cd_gender,
    cd.cd_marital_status,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    AVG(c.c_birth_year) AS avg_birth_year,
    AVG(fd.d_year - c.c_birth_year) AS avg_age_at_first_purchase,
    RANK() OVER (PARTITION BY cp.cp_department ORDER BY COUNT(DISTINCT c.c_customer_id) DESC) AS dept_rank
FROM catalog_page cp
JOIN date_dim sd ON cp.cp_start_date_sk = sd.d_date_sk
JOIN date_dim ed ON cp.cp_end_date_sk = ed.d_date_sk
JOIN customer c ON c.c_first_sales_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
JOIN date_dim fd ON c.c_first_sales_date_sk = fd.d_date_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ca.ca_country = 'United States'
  AND cp.cp_type IN ('monthly', 'quarterly')
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_type,
    cp.cp_department,
    sd.d_year,
    ed.d_year,
    cd.cd_gender,
    cd.cd_marital_status,
    ca.ca_state
HAVING COUNT(DISTINCT c.c_customer_id) >= 10
ORDER BY cp.cp_department, num_customers DESC
LIMIT 100
