SELECT DISTINCT sr.sr_store_sk,
                t.t_shift
FROM store_returns sr
JOIN time_dim t
  ON sr.sr_return_time_sk = t.t_time_sk
WHERE sr.sr_return_amt > 200
  AND t.t_shift = 'first               '
ORDER BY sr.sr_store_sk
