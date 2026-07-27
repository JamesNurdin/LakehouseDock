SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_returned_date_sk,
    t.t_time_id,
    t.t_hour
FROM catalog_returns cr
JOIN time_dim t
  ON cr.cr_returned_time_sk = t.t_time_sk
WHERE cr.cr_returning_cdemo_sk = 206599
  AND t.t_hour = 15
ORDER BY cr.cr_return_amount DESC
LIMIT 100
