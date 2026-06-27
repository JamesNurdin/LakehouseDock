WITH addr_returns AS (
    SELECT
        'refunded' AS address_role,
        ca.ca_state,
        ca.ca_city,
        ca.ca_country,
        ca.ca_location_type,
        wr.wr_return_amt,
        wr.wr_return_quantity
    FROM web_returns wr
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk

    UNION ALL

    SELECT
        'returning' AS address_role,
        ca.ca_state,
        ca.ca_city,
        ca.ca_country,
        ca.ca_location_type,
        wr.wr_return_amt,
        wr.wr_return_quantity
    FROM web_returns wr
    JOIN customer_address ca
        ON wr.wr_returning_addr_sk = ca.ca_address_sk
)
SELECT
    address_role,
    ca_state,
    ca_city,
    ca_country,
    ca_location_type,
    SUM(wr_return_amt) AS total_return_amount,
    COUNT(*) AS return_count,
    AVG(wr_return_quantity) AS avg_return_quantity
FROM addr_returns
GROUP BY address_role, ca_state, ca_city, ca_country, ca_location_type
ORDER BY total_return_amount DESC
LIMIT 20
