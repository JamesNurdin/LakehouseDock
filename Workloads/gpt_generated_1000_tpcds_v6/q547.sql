WITH agg AS (
    SELECT
        ca_state,
        c_birth_year,
        COUNT(*) AS customer_cnt,
        AVG(c_current_cdemo_sk) AS avg_cdemo_sk
    FROM (
        SELECT
            c.c_birth_year,
            c.c_current_cdemo_sk,
            ca.ca_state,
            ca.ca_zip
        FROM tpcds.customer c
        JOIN tpcds.customer_address ca
          ON c.c_current_addr_sk = ca.ca_address_sk
        WHERE c.c_preferred_cust_flag = 'Y'
          AND c.c_birth_year IN (1970, 1991, 1966, 1950)
          AND ca.ca_zip = '90419'
          AND c.c_current_cdemo_sk > 800000
          AND EXISTS (
              SELECT 1
              FROM tpcds.customer_address ca2
              WHERE ca2.ca_state = 'CA'
                AND ca2.ca_address_sk = c.c_current_addr_sk
          )
    ) sub
    GROUP BY ca_state, c_birth_year
)
SELECT
    ca_state,
    c_birth_year,
    customer_cnt,
    avg_cdemo_sk,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY customer_cnt DESC) AS rn_state
FROM agg
ORDER BY customer_cnt DESC, ca_state
LIMIT 100
