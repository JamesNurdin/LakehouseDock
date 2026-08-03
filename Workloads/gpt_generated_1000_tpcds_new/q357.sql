SELECT
  sr.sr_ticket_number,
  sr.sr_return_amt,
  t.t_hour,
  t.t_shift
FROM store_returns AS sr
JOIN time_dim AS t
  ON sr.sr_return_time_sk = t.t_time_sk
WHERE t.t_shift = 'second'
  AND sr.sr_fee > 50.00
ORDER BY sr.sr_ticket_number
LIMIT 100
