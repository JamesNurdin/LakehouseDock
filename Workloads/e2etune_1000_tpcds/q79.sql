WITH filtered AS (
    SELECT cd_demo_sk,
           cd_education_status,
           cd_gender,
           cd_credit_rating,
           cd_purchase_estimate,
           cd_dep_employed_count,
           cd_dep_count,
           cd_marital_status
    FROM customer_demographics
    WHERE cd_marital_status IN ('M', 'S')
      AND cd_credit_rating IN ('Good', 'Low Risk')
      AND cd_purchase_estimate >= 1000
),
aggregated AS (
    SELECT cd_education_status,
           cd_gender,
           AVG(cd_purchase_estimate) AS avg_purchase_estimate,
           SUM(cd_dep_employed_count) AS total_employed_dependents,
           COUNT(*) AS cust_cnt
    FROM filtered
    GROUP BY cd_education_status, cd_gender
),
ranked AS (
    SELECT cd_education_status,
           cd_gender,
           avg_purchase_estimate,
           total_employed_dependents,
           cust_cnt,
           RANK() OVER (PARTITION BY cd_education_status ORDER BY avg_purchase_estimate DESC) AS gender_purchase_rank,
           NTILE(4) OVER (ORDER BY total_employed_dependents DESC) AS employed_dep_quartile
    FROM aggregated
)
SELECT cd_education_status,
       cd_gender,
       avg_purchase_estimate,
       total_employed_dependents,
       cust_cnt,
       gender_purchase_rank,
       employed_dep_quartile
FROM ranked
WHERE gender_purchase_rank <= 2
ORDER BY cd_education_status, gender_purchase_rank
