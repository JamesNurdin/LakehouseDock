WITH high_value_returns AS (
    SELECT sr_addr_sk, sr_return_amt, sr_return_ship_cost, sr_ticket_number
    FROM store_returns
    WHERE sr_return_amt > (SELECT AVG(sr_return_amt) FROM store_returns)
      AND sr_return_ship_cost > 20.00
),
 ticket_range_returns AS (
    SELECT sr_addr_sk, sr_return_amt, sr_return_ship_cost, sr_ticket_number
    FROM store_returns
    WHERE sr_ticket_number BETWEEN 2517570 AND 2517580
),
 combined_returns AS (
    SELECT sr_addr_sk, sr_return_amt, sr_return_ship_cost, sr_ticket_number FROM high_value_returns
    UNION ALL
    SELECT sr_addr_sk, sr_return_amt, sr_return_ship_cost, sr_ticket_number FROM ticket_range_returns
)
SELECT
    ca.ca_city,
    ca.ca_state,
    SUM(cr.sr_return_amt) AS total_return_amt,
    AVG(cr.sr_return_ship_cost) AS avg_ship_cost,
    COUNT(*) AS return_count,
    MIN(cr.sr_return_amt) AS min_return_amt,
    MAX(cr.sr_return_amt) AS max_return_amt
FROM combined_returns cr
JOIN customer_address ca
  ON cr.sr_addr_sk = ca.ca_address_sk
WHERE ca.ca_city IN ('Oakdale', 'Farmington')
  AND ca.ca_state = 'CA'
  AND ca.ca_zip LIKE '9%'
GROUP BY ca.ca_city, ca.ca_state
ORDER BY total_return_amt DESC
LIMIT 100
