WITH customer_demo AS (
   SELECT
       c.c_customer_sk,
       c.c_birth_year,
       c.c_birth_month,
       c.c_birth_country,
       c.c_preferred_cust_flag,
       cd.cd_gender,
       cd.cd_education_status
   FROM customer c
   JOIN customer_demographics cd
     ON c.c_current_cdemo_sk = cd.cd_demo_sk
   WHERE c.c_birth_month IN (4, 5, 6)
     AND c.c_birth_country IN ('IRELAND', 'CYPRUS')
),
agg AS (
   SELECT
       cd_gender,
       cd_education_status,
       COUNT(*) AS num_customers,
       AVG(c_birth_year) AS avg_birth_year,
       SUM(CASE WHEN c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS pref_cust_cnt
   FROM customer_demo
   GROUP BY cd_gender, cd_education_status
   HAVING COUNT(*) >= 10
)
SELECT
    cd_gender,
    cd_education_status,
    num_customers,
    avg_birth_year,
    pref_cust_cnt,
    RANK() OVER (ORDER BY num_customers DESC) AS gender_edu_rank
FROM agg
ORDER BY num_customers DESC
LIMIT 50
