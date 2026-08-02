SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state
FROM
    tpcds.customer c
JOIN
    tpcds.customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
WHERE
    c.c_birth_day = 16
    AND ca.ca_suite_number = 'Suite O   '
LIMIT 100
