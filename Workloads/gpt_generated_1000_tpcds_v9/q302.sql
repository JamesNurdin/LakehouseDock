WITH address_filtered AS (
    SELECT
        ca_address_sk,
        ca_address_id,
        ca_city,
        ca_state,
        ca_location_type
    FROM customer_address
    WHERE ca_location_type IN ('apartment', 'single family')
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    c_email_address,
    ca_address_id,
    ca_city,
    ca_state,
    ca_location_type,
    state_row_num
FROM (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        a.ca_address_id,
        a.ca_city,
        a.ca_state,
        a.ca_location_type,
        ROW_NUMBER() OVER (PARTITION BY a.ca_state ORDER BY c.c_last_name) AS state_row_num
    FROM customer c
    JOIN address_filtered a ON c.c_current_addr_sk = a.ca_address_sk
    WHERE a.ca_location_type = 'apartment'
    
    UNION ALL
    
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        a.ca_address_id,
        a.ca_city,
        a.ca_state,
        a.ca_location_type,
        ROW_NUMBER() OVER (PARTITION BY a.ca_state ORDER BY c.c_last_name) AS state_row_num
    FROM customer c
    JOIN address_filtered a ON c.c_current_addr_sk = a.ca_address_sk
    WHERE a.ca_location_type = 'single family'
      AND c.c_birth_year >= 1975
) combined
ORDER BY ca_state, state_row_num
LIMIT 100
