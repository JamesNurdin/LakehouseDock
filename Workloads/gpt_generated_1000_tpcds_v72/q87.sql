SELECT DISTINCT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_return_tax,
    td.t_hour,
    td.t_am_pm
FROM catalog_returns cr
JOIN time_dim td
  ON cr.cr_returned_time_sk = td.t_time_sk
WHERE cr.cr_return_tax > 50.00
  AND td.t_am_pm = 'PM'
ORDER BY cr.cr_return_amount DESC
LIMIT 100
