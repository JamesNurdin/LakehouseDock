WITH refunded AS (
    SELECT
        ca.ca_state AS state,
        cr.cr_return_amount AS return_amount,
        'refunded' AS addr_type
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_call_center_sk IN (14, 31)
      AND ca.ca_zip LIKE '5%'
),
returning AS (
    SELECT
        ca.ca_state AS state,
        cr.cr_return_amount AS return_amount,
        'returning' AS addr_type
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_returning_addr_sk = ca.ca_address_sk
    WHERE cr.cr_call_center_sk IN (32, 13)
      AND ca.ca_zip LIKE '8%'
)
SELECT
    u.state,
    u.addr_type,
    SUM(u.return_amount) AS total_return_amount
FROM (
    SELECT state, return_amount, addr_type FROM refunded
    UNION ALL
    SELECT state, return_amount, addr_type FROM returning
) u
GROUP BY u.state, u.addr_type
ORDER BY total_return_amount DESC
LIMIT 20
