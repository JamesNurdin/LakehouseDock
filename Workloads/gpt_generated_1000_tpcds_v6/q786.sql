WITH cd_stats AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_est,
        SUM(cd_dep_count) AS sum_dep_cnt,
        MAX(cd_dep_employed_count) AS max_dep_emp,
        COUNT(*) AS demo_cnt
    FROM customer_demographics
    WHERE cd_dep_employed_count >= 2
      AND cd_dep_count BETWEEN 1 AND 4
      AND cd_gender IN ('M', 'F')
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd_stats.cd_gender,
    cd_stats.cd_marital_status,
    c.c_birth_year,
    cd_stats.avg_purchase_est,
    cd_stats.sum_dep_cnt,
    cd_stats.max_dep_emp,
    cd_stats.demo_cnt,
    ROW_NUMBER() OVER (PARTITION BY cd_stats.cd_gender ORDER BY cd_stats.avg_purchase_est DESC) AS gender_rank,
    COUNT(DISTINCT c.c_customer_sk) OVER (PARTITION BY cd_stats.cd_gender) AS distinct_customers_per_gender
FROM customer AS c
JOIN cd_stats
  ON c.c_current_cdemo_sk = cd_stats.cd_demo_sk
WHERE c.c_birth_year BETWEEN 1970 AND 1990
  AND c.c_preferred_cust_flag = 'Y'
  AND c.c_first_shipto_date_sk >= 2451000
  AND c.c_first_shipto_date_sk <= 2453000
  AND c.c_last_review_date > 2452400
ORDER BY cd_stats.avg_purchase_est DESC, c.c_customer_id
LIMIT 100
