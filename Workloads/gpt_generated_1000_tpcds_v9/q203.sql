SELECT
    td.t_hour,
    td.t_shift,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_customers,
    SUM(cr.cr_return_amount) AS total_return_amount
FROM catalog_returns AS cr
JOIN time_dim AS td
    ON cr.cr_returned_time_sk = td.t_time_sk
WHERE cr.cr_return_ship_cost > 500.00
  AND td.t_hour = 16
GROUP BY td.t_hour, td.t_shift
ORDER BY total_return_amount DESC
LIMIT 100
