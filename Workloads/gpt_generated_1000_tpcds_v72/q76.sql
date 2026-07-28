SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    td.t_hour,
    td.t_minute
FROM
    catalog_returns cr
JOIN
    time_dim td
    ON cr.cr_returned_time_sk = td.t_time_sk
WHERE
    cr.cr_fee > 80
    AND td.t_minute IN (1, 5)
LIMIT 100
