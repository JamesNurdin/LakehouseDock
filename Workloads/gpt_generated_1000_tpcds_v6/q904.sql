SELECT DISTINCT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cr.cr_return_amount,
    cr.cr_return_tax
FROM
    catalog_returns cr
JOIN
    customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE
    cr.cr_return_tax > 30.00
    AND cr.cr_return_amount > 100.00
ORDER BY
    cr.cr_return_amount DESC
LIMIT 100
