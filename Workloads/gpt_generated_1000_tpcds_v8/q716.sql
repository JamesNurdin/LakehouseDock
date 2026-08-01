WITH sampled_address AS (
    SELECT *
    FROM customer_address
    TABLESAMPLE BERNOULLI (30)
)
SELECT
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    CASE WHEN ca.ca_gmt_offset > 0 THEN 'East' ELSE 'West' END AS region,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY c.c_birth_year DESC NULLS LAST) AS rn,
    (SELECT COUNT(*) FROM customer c2 WHERE c2.c_current_addr_sk = ca.ca_address_sk) AS cust_count
FROM
    customer c
RIGHT OUTER JOIN sampled_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
WHERE
    ca.ca_suite_number LIKE 'Suite %' AND
    ca.ca_state IN ('NY', 'CA', 'TX') AND
    c.c_preferred_cust_flag = 'Y' AND
    c.c_birth_year BETWEEN 1950 AND 2000 AND
    c.c_email_address LIKE '%@%.org' AND
    c.c_first_sales_date_sk > 2450000 AND
    EXISTS (
        SELECT 1 FROM customer c3
        WHERE c3.c_current_addr_sk = ca.ca_address_sk
          AND c3.c_preferred_cust_flag = 'Y'
    )
UNION DISTINCT
SELECT
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    CASE WHEN ca.ca_gmt_offset > 0 THEN 'East' ELSE 'West' END AS region,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY c.c_birth_year DESC NULLS LAST) AS rn,
    (SELECT COUNT(*) FROM customer c2 WHERE c2.c_current_addr_sk = ca.ca_address_sk) AS cust_count
FROM
    customer c
RIGHT OUTER JOIN sampled_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
WHERE
    ca.ca_suite_number NOT LIKE 'Suite 0%' AND
    ca.ca_state NOT IN ('FL', 'WA') AND
    c.c_preferred_cust_flag = 'N' AND
    c.c_birth_year >= 1980 AND
    c.c_email_address LIKE '%@%.com' AND
    c.c_first_sales_date_sk BETWEEN 2450390 AND 2452000 AND
    EXISTS (
        SELECT 1 FROM customer c3
        WHERE c3.c_current_addr_sk = ca.ca_address_sk
          AND c3.c_preferred_cust_flag = 'N'
    )
LIMIT 100
