WITH max_birth AS (
    SELECT MAX(c_birth_year) AS max_year
    FROM tpcds.customer
)
SELECT
    ca.ca_state,
    CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Regular' END AS cust_type,
    COUNT(*) AS customer_cnt,
    AVG(c.c_birth_year) AS avg_birth_year,
    SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_cnt,
    MIN(c.c_birth_year) AS min_birth_year,
    MAX(c.c_birth_year) AS max_birth_year
FROM tpcds.customer c
JOIN tpcds.customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
WHERE
    c.c_birth_year < (SELECT max_year FROM max_birth)
    AND c.c_salutation = 'Mr.'
    AND ca.ca_county = 'Marshall County'
    AND NOT EXISTS (
        SELECT 1
        FROM tpcds.customer_address ca2
        WHERE ca2.ca_address_sk = c.c_current_addr_sk
          AND ca2.ca_zip = '00000'
    )
GROUP BY
    ca.ca_state,
    CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Regular' END
ORDER BY
    customer_cnt DESC,
    ca.ca_state
