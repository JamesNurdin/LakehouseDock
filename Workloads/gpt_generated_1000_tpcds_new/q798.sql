WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_current_addr_sk,
        c.c_birth_year,
        c.c_birth_month,
        c.c_birth_day,
        c.c_first_sales_date_sk
    FROM tpcds.customer c
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_country = 'United States'
      AND c.c_birth_year BETWEEN 1950 AND 1990
      AND c.c_first_sales_date_sk > (
            SELECT MAX(c2.c_first_sales_date_sk)
            FROM tpcds.customer c2
            WHERE c2.c_birth_year = 1960
        )
      AND c.c_customer_id IN (
            SELECT c3.c_customer_id
            FROM tpcds.customer c3
            WHERE c3.c_birth_month = 7
              AND c3.c_birth_day = 15
        )
      AND c.c_customer_id NOT IN (
            SELECT c4.c_customer_id
            FROM tpcds.customer c4
            WHERE c4.c_login LIKE 'test%'
        )
),
eligible_customers AS (
    SELECT
        fc.c_customer_sk,
        fc.c_customer_id,
        fc.c_current_addr_sk,
        fc.c_birth_year
    FROM filtered_customers fc
    EXCEPT
    SELECT
        c5.c_customer_sk,
        c5.c_customer_id,
        c5.c_current_addr_sk,
        c5.c_birth_year
    FROM tpcds.customer c5
    WHERE c5.c_birth_month = 12
      AND c5.c_birth_day = 25
),
joined AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        ec.c_customer_sk,
        ec.c_birth_year,
        ca.ca_zip
    FROM eligible_customers ec
    JOIN tpcds.customer_address ca
        ON ec.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IN ('CA', 'TX', 'NY', 'FL')
      AND EXISTS (
            SELECT 1
            FROM tpcds.customer_address ca2
            WHERE ca2.ca_zip = ca.ca_zip
              AND ca2.ca_state = ca.ca_state
              AND ca2.ca_city = ca.ca_city
            LIMIT 1
        )
),
state_city_agg AS (
    SELECT
        j.ca_state,
        j.ca_city,
        COUNT(DISTINCT j.c_customer_sk) AS cust_cnt,
        AVG(j.c_birth_year) AS avg_birth_year
    FROM joined j
    GROUP BY j.ca_state, j.ca_city
)
SELECT
    sca.ca_state,
    sca.ca_city,
    SUM(sca.cust_cnt) AS total_customers,
    AVG(sca.avg_birth_year) AS avg_of_avg_birth_year
FROM state_city_agg sca
GROUP BY ROLLUP (sca.ca_state, sca.ca_city)
ORDER BY
    CASE WHEN sca.ca_state IS NULL THEN 1 ELSE 0 END,
    sca.ca_state,
    sca.ca_city
LIMIT 100
