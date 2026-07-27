SELECT
    ca_state,
    COUNT(*) AS address_count
FROM
    customer_address
WHERE
    ca_state = 'CA'
    AND ca_zip LIKE '9%'
GROUP BY
    ca_state
LIMIT 100
