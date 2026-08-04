WITH filtered AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_country,
        c.c_first_shipto_date_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_college_count,
        cd.cd_dep_employed_count,
        cd.cd_credit_rating
    FROM tpcds.customer c
    JOIN tpcds.customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_country IN ('JORDAN', 'CHILE')
      AND c.c_first_shipto_date_sk BETWEEN 2449500 AND 2452000
      AND cd.cd_marital_status = 'M'
      AND cd.cd_dep_college_count >= 2
      AND cd.cd_credit_rating = 'Good'
),
set_a AS (
    SELECT c_customer_sk
    FROM filtered
    WHERE cd_credit_rating = 'Good'
),
set_b AS (
    SELECT c_customer_sk
    FROM filtered
    WHERE cd_credit_rating = 'Poor'
),
diff_keys AS (
    SELECT c_customer_sk FROM set_a
    EXCEPT
    SELECT c_customer_sk FROM set_b
),
agg_union AS (
    SELECT
        c_birth_country,
        cd_gender,
        CASE WHEN cd_marital_status = 'M' THEN 'Married' ELSE 'Other' END AS marital_category,
        COUNT(*) AS cust_cnt,
        SUM(cd_dep_employed_count) AS total_employed_dep,
        MIN(cd_dep_college_count) AS min_college_dep,
        MAX(cd_dep_college_count) AS max_college_dep
    FROM filtered
    GROUP BY GROUPING SETS (
        (c_birth_country, cd_gender, cd_marital_status),
        (cd_gender)
    )
    UNION DISTINCT
    SELECT
        NULL AS c_birth_country,
        cd_gender,
        'All' AS marital_category,
        COUNT(*) AS cust_cnt,
        SUM(cd_dep_employed_count) AS total_employed_dep,
        MIN(cd_dep_college_count) AS min_college_dep,
        MAX(cd_dep_college_count) AS max_college_dep
    FROM filtered
    GROUP BY cd_gender
)
SELECT
    a.c_birth_country,
    a.cd_gender,
    a.marital_category,
    a.cust_cnt,
    a.total_employed_dep,
    a.min_college_dep,
    a.max_college_dep
FROM agg_union a
WHERE a.cust_cnt > 0
ORDER BY a.cust_cnt DESC, a.c_birth_country
