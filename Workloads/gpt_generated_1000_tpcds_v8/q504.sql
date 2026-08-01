WITH sampled_customers AS (
  SELECT c_customer_id,
         c_current_cdemo_sk,
         c_salutation,
         c_birth_day
  FROM tpcds.customer
  TABLESAMPLE BERNOULLI (10)
  WHERE c_salutation = 'Mr.'
    AND c_birth_day BETWEEN 14 AND 30
    AND c_current_cdemo_sk IS NOT NULL
),

demo_joined AS (
  SELECT sc.c_customer_id,
         sc.c_current_cdemo_sk,
         cd.cd_gender,
         cd.cd_marital_status,
         cd.cd_purchase_estimate,
         cd.cd_dep_count,
         cd.cd_dep_college_count
  FROM sampled_customers sc
  JOIN tpcds.customer_demographics cd
    ON sc.c_current_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_purchase_estimate > 3000
    AND cd.cd_dep_count <= 3
),

with_lateral AS (
  SELECT dj.c_customer_id,
         dj.c_current_cdemo_sk,
         dj.cd_gender,
         dj.cd_marital_status,
         dj.cd_purchase_estimate,
         dj.cd_dep_count,
         dj.cd_dep_college_count,
         dep_calc.dep_total
  FROM demo_joined dj,
       LATERAL (
         SELECT dj.cd_dep_count + dj.cd_dep_college_count AS dep_total
       ) AS dep_calc
),

unioned AS (
  SELECT
    wl.c_current_cdemo_sk,
    wl.cd_gender,
    SUM(wl.cd_purchase_estimate) AS total_purchase,
    COUNT(*) AS cust_cnt,
    MIN(wl.cd_dep_count) AS min_dep,
    MAX(wl.dep_total) AS max_dep_total
  FROM with_lateral wl
  GROUP BY GROUPING SETS ((wl.c_current_cdemo_sk, wl.cd_gender), (wl.c_current_cdemo_sk))
  UNION
  SELECT
    wl.c_current_cdemo_sk,
    wl.cd_gender,
    SUM(wl.cd_purchase_estimate) AS total_purchase,
    COUNT(*) AS cust_cnt,
    MIN(wl.cd_dep_count) AS min_dep,
    MAX(wl.dep_total) AS max_dep_total
  FROM with_lateral wl
  WHERE wl.cd_gender = 'F'
  GROUP BY GROUPING SETS ((wl.c_current_cdemo_sk, wl.cd_gender), (wl.c_current_cdemo_sk))
),

excepted AS (
  SELECT u.c_current_cdemo_sk
  FROM unioned u
  EXCEPT
  SELECT wl.c_current_cdemo_sk
  FROM with_lateral wl
  WHERE wl.cd_gender = 'M'
)

SELECT
  u.c_current_cdemo_sk,
  u.cd_gender,
  u.total_purchase,
  u.cust_cnt,
  u.min_dep,
  u.max_dep_total,
  CASE WHEN e.c_current_cdemo_sk IS NOT NULL THEN true ELSE false END AS is_excluded
FROM unioned u
LEFT JOIN excepted e
  ON u.c_current_cdemo_sk = e.c_current_cdemo_sk
ORDER BY u.total_purchase DESC
LIMIT 100
