SELECT d.d_date,
       d.d_day_name,
       wr.wr_return_amt,
       wr.wr_net_loss
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_same_day_ly = 2414660
  AND wr.wr_net_loss > 100
LIMIT 100
