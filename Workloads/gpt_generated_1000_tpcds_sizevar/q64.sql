SELECT 
  cr.cr_returned_date_sk,
  cr.cr_return_amount,
  cr.cr_store_credit,
  td.t_hour,
  td.t_minute,
  td.t_am_pm
FROM catalog_returns AS cr
JOIN time_dim AS td
  ON cr.cr_returned_time_sk = td.t_time_sk
WHERE td.t_am_pm = 'PM'
  AND cr.cr_store_credit > 100.00
ORDER BY cr.cr_return_amount DESC
LIMIT 10
