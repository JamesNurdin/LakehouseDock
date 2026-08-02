WITH cust_agg AS (
    SELECT
        c_current_cdemo_sk,
        COUNT(*) AS cust_cnt,
        AVG(c_birth_year) AS avg_birth_year,
        MIN(c_birth_year) AS min_birth_year,
        MAX(c_birth_year) AS max_birth_year
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'
      AND c_birth_year BETWEEN 1960 AND 1990
      AND c_birth_month = 7
      AND c_last_review_date > 2452000
      AND c_current_hdemo_sk IS NOT NULL
    GROUP BY c_current_cdemo_sk
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(ca.cust_cnt) AS total_customers,
    AVG(ca.avg_birth_year) AS avg_birth_year,
    (SELECT COUNT(*) FROM customer_demographics) AS total_demo_count,
    MAX(l_max.max_estimate) AS max_purchase_estimate_by_demo
FROM cust_agg ca
JOIN customer_demographics cd
    ON ca.c_current_cdemo_sk = cd.cd_demo_sk
CROSS JOIN LATERAL (
    SELECT MAX(cd2.cd_purchase_estimate) AS max_estimate
    FROM customer_demographics cd2
    WHERE cd2.cd_demo_sk = ca.c_current_cdemo_sk
) AS l_max
WHERE cd.cd_credit_rating = 'A'
  AND cd.cd_dep_employed_count >= 2
  AND cd.cd_purchase_estimate BETWEEN 3000 AND 10000
  AND cd.cd_dep_count IN (1, 2, 3, 4, 5)
  AND cd.cd_gender IS NOT NULL
GROUP BY GROUPING SETS (
    (cd.cd_gender, cd.cd_marital_status),
    (cd.cd_gender),
    (cd.cd_marital_status),
    ()
)
HAVING SUM(ca.cust_cnt) > 10
ORDER BY total_customers DESC, avg_birth_year
LIMIT 100
