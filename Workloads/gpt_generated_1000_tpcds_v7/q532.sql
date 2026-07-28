SELECT
    s.s_state,
    s.s_city,
    s.s_division_name,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_transactions,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_fee) AS avg_fee,
    MIN(sr.sr_return_ship_cost) AS min_ship_cost,
    MAX(sr.sr_return_ship_cost) AS max_ship_cost
FROM tpcds.store_returns AS sr
JOIN tpcds.store AS s
  ON sr.sr_store_sk = s.s_store_sk
WHERE s.s_state = 'CA'
  AND s.s_city = 'Springfield'
  AND s.s_division_id = 1
  AND sr.sr_return_ship_cost >= 1000.00
  AND sr.sr_fee > 10.00
GROUP BY
    s.s_state,
    s.s_city,
    s.s_division_name
HAVING COUNT(*) > 10
ORDER BY total_return_amount DESC
