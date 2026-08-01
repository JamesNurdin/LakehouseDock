WITH full_join AS (
  SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    c.c_login,
    c.c_birth_day,
    c.c_current_cdemo_sk,
    cd.cd_demo_sk,
    cd.cd_gender,
    cd.cd_credit_rating,
    cd.cd_dep_employed_count,
    cd.cd_dep_college_count
  FROM tpcds.customer c
  FULL OUTER JOIN tpcds.customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT DISTINCT
  fj.c_customer_id,
  fj.c_first_name,
  fj.c_last_name,
  CONCAT(fj.c_first_name, ' ', fj.c_last_name) AS full_name,
  SUBSTRING(fj.c_login FROM 1 FOR 5) AS login_prefix,
  REGEXP_EXTRACT(fj.c_email_address, '([^@]+)@(.+)$', 2) AS email_domain,
  CASE
    WHEN fj.cd_credit_rating = 'Low Risk' THEN 'Safe'
    WHEN fj.cd_credit_rating = 'High Risk' THEN 'Risky'
    ELSE 'Medium'
  END AS rating_category,
  fj.cd_gender,
  fj.cd_dep_employed_count,
  fj.cd_dep_college_count,
  (SELECT COUNT(*) FROM tpcds.customer c2 WHERE c2.c_current_cdemo_sk = fj.c_current_cdemo_sk) AS same_demo_customer_count,
  LAG(fj.c_birth_day) OVER (PARTITION BY fj.cd_gender ORDER BY fj.c_birth_day) AS prev_birth_day,
  SUM(fj.cd_dep_employed_count) OVER (
    PARTITION BY fj.cd_credit_rating
    ORDER BY fj.cd_demo_sk
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cum_dep_employed
FROM full_join fj
WHERE
  REGEXP_LIKE(fj.c_email_address, '^.+@.+\\.com$')
  AND fj.c_login LIKE 'admin%'
  AND fj.c_current_cdemo_sk IN (
    SELECT cd_demo_sk FROM tpcds.customer_demographics WHERE cd_gender = 'F'
  )
  AND fj.c_birth_day = (SELECT MAX(c_birth_day) FROM tpcds.customer)
  AND NOT EXISTS (
    SELECT 1 FROM tpcds.customer_demographics cd2
    WHERE cd2.cd_demo_sk = fj.c_current_cdemo_sk
      AND cd2.cd_credit_rating = 'Low Risk'
  )
ORDER BY rating_category, fj.c_last_name ASC
