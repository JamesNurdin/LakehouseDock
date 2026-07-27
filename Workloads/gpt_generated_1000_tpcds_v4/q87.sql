SELECT
    store_returns.sr_store_sk,
    time_dim.t_shift,
    SUM(store_returns.sr_return_amt) AS total_return_amount
FROM tpcds.store_returns AS store_returns
JOIN tpcds.time_dim AS time_dim
    ON store_returns.sr_return_time_sk = time_dim.t_time_sk
WHERE store_returns.sr_return_tax > 50.00
  AND time_dim.t_am_pm = 'PM'
GROUP BY store_returns.sr_store_sk, time_dim.t_shift
ORDER BY total_return_amount DESC
LIMIT 100
