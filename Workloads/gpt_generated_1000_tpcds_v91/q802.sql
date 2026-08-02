SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_year,
    ca.ca_city,
    ca.ca_state
FROM
    tpcds.customer AS c
JOIN
    tpcds.customer_address AS ca
    ON c.c_current_addr_sk = ca.ca_address_sk
WHERE
    ca.ca_country = 'United States'
    AND c.c_birth_month = 12
    AND c.c_first_shipto_date_sk = 2452198
ORDER BY
    c.c_last_name,
    c.c_first_name
LIMIT 100
