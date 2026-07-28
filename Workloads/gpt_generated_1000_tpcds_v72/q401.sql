SELECT
    c.c_first_name,
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk)        AS customer_count,
    AVG(cd.cd_purchase_estimate)           AS avg_purchase_estimate,
    MIN(c.c_birth_year)                    AS min_birth_year,
    MAX(c.c_birth_year)                    AS max_birth_year
FROM tpcds.customer c
JOIN tpcds.customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN tpcds.customer_demographics cd
  ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE c.c_birth_year >= 1950
  AND c.c_birth_year <= 1990
  AND ca.ca_state IN ('CA', 'TX', 'NY')
  AND ca.ca_zip LIKE '5____'
  AND c.c_preferred_cust_flag = 'Y'
  AND EXISTS (
        SELECT 1
        FROM tpcds.customer_demographics cd_sub
        WHERE cd_sub.cd_demo_sk = c.c_current_cdemo_sk
          AND cd_sub.cd_gender = 'M'
          AND cd_sub.cd_education_status = 'Advanced Degree'
          AND cd_sub.cd_dep_employed_count >= 2
      )
GROUP BY GROUPING SETS (
    (c.c_first_name, ca.ca_city),
    (c.c_first_name),
    (ca.ca_city),
    ()
)
ORDER BY customer_count DESC, c.c_first_name
LIMIT 100
