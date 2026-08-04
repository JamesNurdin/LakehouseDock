WITH demographic_filtered AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM tpcds.customer_demographics
    WHERE cd_gender IN ('M', 'F')
      AND cd_marital_status = 'M'
      AND cd_education_status = 'College'
      AND cd_purchase_estimate > 500
      AND cd_dep_count >= 2
),
customer_filtered AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        c_current_cdemo_sk,
        c_first_name,
        c_last_name,
        c_birth_day,
        c_birth_month,
        c_birth_year,
        c_birth_country,
        c_last_review_date,
        c_current_addr_sk,
        c_preferred_cust_flag
    FROM tpcds.customer
    WHERE c_birth_year BETWEEN 1950 AND 1990
      AND c_birth_country = 'United States'
      AND c_last_review_date > 2452000
      AND c_preferred_cust_flag = 'Y'
      AND c_current_addr_sk > 1000000
),
intersect_keys AS (
    SELECT cd_demo_sk FROM demographic_filtered
    INTERSECT
    SELECT c_current_cdemo_sk FROM customer_filtered
)
SELECT
    cf.c_customer_id,
    cf.c_first_name,
    cf.c_last_name,
    df.cd_gender,
    df.cd_marital_status,
    df.cd_education_status,
    df.cd_purchase_estimate,
    cf.c_birth_year,
    ROW_NUMBER() OVER (PARTITION BY df.cd_gender ORDER BY cf.c_birth_year DESC) AS rn_gender_birth,
    CASE
        WHEN df.cd_dep_employed_count > df.cd_dep_college_count THEN 'MoreEmployed'
        ELSE 'MoreCollege'
    END AS dep_employment_flag,
    (
        SELECT avg(d2.cd_purchase_estimate)
        FROM tpcds.customer_demographics d2
        WHERE d2.cd_gender = df.cd_gender
    ) AS avg_purchase_estimate_by_gender,
    EXISTS (
        SELECT 1
        FROM tpcds.customer c2
        WHERE c2.c_current_cdemo_sk = cf.c_current_cdemo_sk
          AND c2.c_birth_year = cf.c_birth_year
          AND c2.c_customer_sk <> cf.c_customer_sk
    ) AS has_peer_same_demo_and_birthyear
FROM customer_filtered cf
FULL OUTER JOIN demographic_filtered df
    ON cf.c_current_cdemo_sk = df.cd_demo_sk
WHERE cf.c_current_cdemo_sk IN (SELECT cd_demo_sk FROM intersect_keys)
   OR df.cd_demo_sk IN (SELECT cd_demo_sk FROM intersect_keys)
ORDER BY rn_gender_birth ASC, cf.c_birth_year DESC
LIMIT 100
