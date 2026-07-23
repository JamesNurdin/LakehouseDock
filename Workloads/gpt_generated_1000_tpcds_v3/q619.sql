SELECT
    ca.ca_city,
    ca.ca_state,
    SUM(sr.sr_return_amt) AS total_return_amount,
    COUNT(*) AS return_count
FROM
    store_returns sr
JOIN
    customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
WHERE
    ca.ca_zip = '39431'
    AND sr.sr_return_amt > 100
GROUP BY
    ca.ca_city,
    ca.ca_state
ORDER BY
    total_return_amount DESC
