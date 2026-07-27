WITH state_returns AS (
    SELECT
        ca.ca_state,
        ca.ca_location_type,
        ca.ca_gmt_offset,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        AVG(sr.sr_store_credit) AS avg_store_credit
    FROM store_returns sr
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_ship_cost > 100
      AND sr.sr_return_amt_inc_tax BETWEEN 50 AND 1000
      AND ca.ca_zip LIKE '8%'
      AND ca.ca_gmt_offset <= -5
      AND ca.ca_location_type IN ('condo', 'apartment')
    GROUP BY ca.ca_state, ca.ca_location_type, ca.ca_gmt_offset
)
SELECT
    sr.ca_state,
    sr.ca_location_type,
    sr.ca_gmt_offset,
    sr.total_return_amt,
    sr.total_return_qty,
    sr.avg_store_credit,
    RANK() OVER (ORDER BY sr.total_return_amt DESC) AS revenue_rank,
    (
        SELECT COUNT(*)
        FROM state_returns sr2
        WHERE sr2.total_return_amt > sr.total_return_amt
    ) AS higher_state_count
FROM state_returns sr
WHERE sr.total_return_amt > (
    SELECT AVG(total_return_amt)
    FROM state_returns
)
ORDER BY sr.total_return_amt DESC
LIMIT 100
