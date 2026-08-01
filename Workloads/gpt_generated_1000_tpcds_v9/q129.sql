WITH filtered_base AS (
   SELECT
       c.c_customer_sk,
       c.c_preferred_cust_flag,
       c.c_first_name,
       c.c_birth_year,
       c.c_birth_country,
       c.c_first_shipto_date_sk,
       c.c_current_cdemo_sk,
       cd.cd_demo_sk,
       cd.cd_gender,
       cd.cd_marital_status,
       cd.cd_credit_rating,
       cd.cd_dep_employed_count,
       cd.cd_purchase_estimate
   FROM tpcds.customer c
   JOIN tpcds.customer_demographics cd
     ON c.c_current_cdemo_sk = cd.cd_demo_sk
   WHERE c.c_preferred_cust_flag = 'Y'
     AND c.c_birth_year BETWEEN 1970 AND 1990
     AND c.c_birth_country = 'United States'
     AND c.c_first_shipto_date_sk IN (2452550, 2451217, 2450421)
     AND c.c_first_name IN ('Henry', 'Patrick')
     AND cd.cd_credit_rating IN ('Good', 'Low Risk')
     AND cd.cd_dep_employed_count >= 1
)
SELECT
   f.c_preferred_cust_flag,
   f.cd_marital_status,
   f.cd_credit_rating,
   COUNT(DISTINCT f.c_customer_sk) AS num_customers,
   SUM(f.cd_dep_employed_count) AS total_employed_dependents,
   AVG(f.cd_purchase_estimate) AS avg_purchase_estimate,
   MAX(f.cd_purchase_estimate) AS max_purchase_estimate,
   (SELECT MIN(cd2.cd_purchase_estimate)
    FROM tpcds.customer_demographics cd2
    WHERE cd2.cd_credit_rating = 'Good') AS min_estimate_good_credit,
   SUM(COUNT(DISTINCT f.c_customer_sk)) OVER (PARTITION BY f.c_preferred_cust_flag) AS sum_custs_by_flag
FROM filtered_base f
WHERE NOT EXISTS (
    SELECT 1
    FROM tpcds.customer_demographics cd_ex
    WHERE cd_ex.cd_demo_sk = f.c_current_cdemo_sk
      AND cd_ex.cd_credit_rating = 'High Risk'
)
GROUP BY
   GROUPING SETS (
      (f.c_preferred_cust_flag, f.cd_marital_status, f.cd_credit_rating),
      (f.c_preferred_cust_flag, f.cd_marital_status),
      (f.c_preferred_cust_flag),
      ()
   )
ORDER BY num_customers DESC
LIMIT 100
