WITH base AS (
  SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    AVG(year(current_date) - c.c_birth_year) AS avg_age,
    SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_customers
  FROM customer c
  JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
  WHERE c.c_preferred_cust_flag = 'Y'
    AND c.c_birth_year BETWEEN 1960 AND 1990
    AND c.c_current_cdemo_sk IN (980124, 819667, 1473522, 1703214, 953372)
  GROUP BY
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
  HAVING COUNT(DISTINCT c.c_customer_id) >= 10
)
SELECT
  b.cd_gender,
  b.cd_marital_status,
  b.cd_education_status,
  b.num_customers,
  b.avg_age,
  b.preferred_customers,
  RANK() OVER (ORDER BY b.num_customers DESC) AS gender_marital_rank,
  (SELECT COUNT(*) FROM promotion p WHERE p.p_start_date_sk >= 2449000 AND p.p_end_date_sk <= 2451000) AS total_promos,
  (SELECT SUM(p.p_cost) FROM promotion p WHERE p.p_start_date_sk >= 2449000 AND p.p_end_date_sk <= 2451000) AS total_promo_cost,
  (SELECT COUNT(*) FROM reason r WHERE r.r_reason_id IS NOT NULL) AS total_reasons,
  (SELECT COUNT(*) FROM reason r WHERE r.r_reason_desc LIKE '%discount%') AS discount_reason_cnt
FROM base b
ORDER BY b.avg_age DESC
LIMIT 20
