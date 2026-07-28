WITH ranked_customers AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_education_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating,
        d.cd_dep_count,
        d.cd_dep_employed_count,
        d.cd_dep_college_count,
        (d.cd_dep_count + d.cd_dep_employed_count + d.cd_dep_college_count) AS total_dependents,
        CASE WHEN d.cd_dep_employed_count > 2 THEN 'High' ELSE 'Low' END AS emp_dep_level,
        ROW_NUMBER() OVER (PARTITION BY d.cd_gender ORDER BY d.cd_purchase_estimate DESC) AS gender_purchase_rank
    FROM tpcds.customer AS c
    JOIN tpcds.customer_demographics AS d
        ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE c.c_birth_year BETWEEN 1960 AND 1990
      AND c.c_preferred_cust_flag = 'Y'
      AND d.cd_credit_rating IN ('A', 'B', 'C')
      AND d.cd_education_status = 'Advanced Degree'
      AND d.cd_dep_employed_count >= 1
      AND c.c_current_hdemo_sk IN (3219, 3014)
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    cd_gender,
    cd_education_status,
    cd_purchase_estimate,
    cd_credit_rating,
    cd_dep_count,
    cd_dep_employed_count,
    cd_dep_college_count,
    total_dependents,
    emp_dep_level,
    gender_purchase_rank
FROM ranked_customers
ORDER BY gender_purchase_rank ASC, total_dependents DESC
LIMIT 100
