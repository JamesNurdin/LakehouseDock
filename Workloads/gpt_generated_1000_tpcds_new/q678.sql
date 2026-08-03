WITH sampled_customer AS (
    SELECT 
        c_customer_sk,
        c_customer_id,
        c_current_cdemo_sk,
        c_current_hdemo_sk,
        c_birth_month,
        c_birth_year,
        c_preferred_cust_flag
    FROM tpcds.customer
    TABLESAMPLE BERNOULLI (10)
),
unioned AS (
    SELECT 
        sc.c_customer_id,
        cd.cd_gender,
        hd.hd_vehicle_count,
        CASE WHEN cd.cd_credit_rating = 'Good' THEN 1 ELSE 0 END AS good_credit_flag,
        cd.cd_purchase_estimate
    FROM sampled_customer sc
    FULL OUTER JOIN tpcds.customer_demographics cd
        ON sc.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN tpcds.household_demographics hd
        ON sc.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE sc.c_birth_month = 5
      AND sc.c_birth_year = 1975
      AND cd.cd_marital_status = 'M'
      AND hd.hd_vehicle_count >= 2
      AND sc.c_preferred_cust_flag = 'Y'

    UNION DISTINCT

    SELECT 
        sc.c_customer_id,
        cd.cd_gender,
        hd.hd_vehicle_count,
        CASE WHEN cd.cd_credit_rating = 'Good' THEN 1 ELSE 0 END AS good_credit_flag,
        cd.cd_purchase_estimate
    FROM sampled_customer sc
    FULL OUTER JOIN tpcds.customer_demographics cd
        ON sc.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN tpcds.household_demographics hd
        ON sc.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE sc.c_birth_month = 12
      AND sc.c_birth_year = 1980
      AND cd.cd_marital_status = 'S'
      AND hd.hd_vehicle_count <= 3
      AND sc.c_preferred_cust_flag = 'N'
)
SELECT 
    good_credit_flag,
    COUNT(DISTINCT c_customer_id) AS customer_cnt,
    SUM(cd_purchase_estimate) AS total_purchase_est,
    AVG(cd_purchase_estimate) AS avg_purchase_est,
    MIN(cd_purchase_estimate) AS min_purchase_est,
    MAX(cd_purchase_estimate) AS max_purchase_est,
    (SELECT AVG(cd_purchase_estimate) FROM tpcds.customer_demographics WHERE cd_credit_rating = 'Good') AS overall_good_avg_purchase
FROM unioned
GROUP BY good_credit_flag
ORDER BY total_purchase_est DESC
LIMIT 100
