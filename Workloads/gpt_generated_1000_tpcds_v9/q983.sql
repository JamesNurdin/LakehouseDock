WITH base_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        c.c_last_review_date,
        c.c_current_hdemo_sk,
        ca.ca_state,
        ca.ca_city,
        ca.ca_zip
    FROM tpcds.customer c
    JOIN tpcds.customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        c.c_current_hdemo_sk IN (1461, 3876, 6247)
        AND c.c_last_review_date BETWEEN 2452313 AND 2452634
        AND c.c_birth_year BETWEEN 1950 AND 1995
        AND ca.ca_country = 'United States'
        AND ca.ca_street_type IN ('Road', 'Blvd', 'Street')
        AND ca.ca_state IS NOT NULL
)
SELECT
    combined.c_customer_sk,
    combined.c_customer_id,
    combined.c_first_name,
    combined.c_last_name,
    combined.c_birth_year,
    combined.ca_state,
    combined.ca_city,
    combined.ca_zip,
    combined.rn_state_birth_desc,
    combined.global_review_rank
FROM (
    SELECT
        bc.c_customer_sk,
        bc.c_customer_id,
        bc.c_first_name,
        bc.c_last_name,
        bc.c_birth_year,
        bc.ca_state,
        bc.ca_city,
        bc.ca_zip,
        ROW_NUMBER() OVER (PARTITION BY bc.ca_state ORDER BY bc.c_birth_year DESC) AS rn_state_birth_desc,
        RANK() OVER (ORDER BY bc.c_last_review_date DESC) AS global_review_rank
    FROM base_customers bc
    WHERE bc.c_current_hdemo_sk = 1461

    UNION ALL

    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        ca_l.ca_state,
        ca_l.ca_city,
        ca_l.ca_zip,
        ROW_NUMBER() OVER (PARTITION BY ca_l.ca_state ORDER BY c.c_birth_year DESC) AS rn_state_birth_desc,
        RANK() OVER (ORDER BY c.c_last_review_date DESC) AS global_review_rank
    FROM tpcds.customer c
    CROSS JOIN LATERAL (
        SELECT *
        FROM tpcds.customer_address ca
        WHERE ca.ca_address_sk = c.c_current_addr_sk
          AND ca.ca_street_type = 'Road'
          AND ca.ca_country = 'United States'
    ) ca_l
    WHERE
        c.c_birth_year BETWEEN 1960 AND 2000
        AND c.c_last_review_date >= 2452400
        AND c.c_current_hdemo_sk = 3876
) AS combined
ORDER BY combined.global_review_rank, combined.rn_state_birth_desc
LIMIT 100
