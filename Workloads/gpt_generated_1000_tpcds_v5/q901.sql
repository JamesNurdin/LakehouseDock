SELECT
  s.s_store_name,
  s.s_city,
  s.s_state,
  SUM(sr.sr_return_amt) AS total_return_amount,
  COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
FROM tpcds.store AS s
JOIN tpcds.store_returns AS sr
  ON sr.sr_store_sk = s.s_store_sk
WHERE s.s_county = 'Gogebic County'
  AND sr.sr_return_amt > 100
GROUP BY s.s_store_name, s.s_city, s.s_state
ORDER BY total_return_amount DESC
LIMIT 100
