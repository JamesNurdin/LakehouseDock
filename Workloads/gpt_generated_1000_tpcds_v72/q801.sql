WITH cust_agg AS (
    SELECT
        c_current_cdemo_sk,
        COUNT(*) AS total_customers,
        COUNT(CASE WHEN c_preferred_cust_flag = 'Y' THEN 1 END) AS preferred_cnt,
        MIN(c_birth_year) AS min_birth_year,
        MAX(c_birth_year) AS max_birth_year
    FROM tpcds.customer
    WHERE c_birth_year IS NOT NULL
    GROUP BY c_current_cdemo_sk
)
SELECT
    d.cd_demo_sk,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    d.cd_credit_rating,
    d.cd_dep_employed_count,
    a.total_customers,
    a.preferred_cnt,
    CASE
        WHEN d.cd_credit_rating = 'Excellent' THEN 'Top'
        WHEN d.cd_credit_rating = 'Good' THEN 'Good'
        ELSE 'Other'
    END AS credit_category,
    ROW_NUMBER() OVER (PARTITION BY d.cd_gender ORDER BY a.total_customers DESC) AS gender_rank
FROM cust_agg a
JOIN tpcds.customer_demographics d
    ON a.c_current_cdemo_sk = d.cd_demo_sk
WHERE
    d.cd_gender = 'M'
    AND d.cd_marital_status = 'S'
    AND d.cd_dep_employed_count >= 2
    AND d.cd_dep_college_count <= 5
    AND d.cd_education_status IN ('Secondary', 'Advanced Degree')
    AND a.total_customers >= 5
ORDER BY d.cd_gender, gender_rank
LIMIT 100
