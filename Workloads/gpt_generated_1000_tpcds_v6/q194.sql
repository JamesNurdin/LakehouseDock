WITH catalog_data AS (
    SELECT DISTINCT
        ca.ca_state AS state,
        cr.cr_return_amount AS return_amount,
        CASE WHEN cr.cr_return_quantity > 1 THEN 'MULTI' ELSE 'SINGLE' END AS return_type
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_amount > 0
),
store_data AS (
    SELECT DISTINCT
        ca.ca_state AS state,
        sr.sr_return_amt AS return_amount,
        CASE WHEN sr.sr_return_quantity > 1 THEN 'MULTI' ELSE 'SINGLE' END AS return_type
    FROM store_returns sr
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_amt > 0
)
SELECT
    combined.state,
    combined.return_type,
    SUM(combined.return_amount) AS total_return_amount
FROM (
    SELECT * FROM catalog_data
    UNION ALL
    SELECT * FROM store_data
) AS combined
WHERE EXISTS (
    SELECT 1
    FROM warehouse w
    WHERE w.w_state = combined.state
      AND w.w_warehouse_sq_ft > 100000
)
GROUP BY combined.state, combined.return_type
ORDER BY total_return_amount DESC
LIMIT 100
