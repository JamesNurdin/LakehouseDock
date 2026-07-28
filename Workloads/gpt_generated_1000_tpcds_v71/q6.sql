SELECT sr.sr_store_sk,
       sr.sr_return_amt,
       sr.sr_store_credit,
       t.t_shift,
       t.t_minute
FROM store_returns sr
JOIN time_dim t
  ON sr.sr_return_time_sk = t.t_time_sk
WHERE t.t_shift = 'first'
  AND sr.sr_store_credit > 20
  AND t.t_minute = 15
LIMIT 100
