SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cr.cr_refunded_cash,
    cr.cr_return_tax
FROM
    catalog_returns cr
JOIN
    customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE
    cr.cr_refunded_cash > 500.00
    AND c.c_birth_day = 15
ORDER BY
    cr.cr_refunded_cash DESC
LIMIT 100
