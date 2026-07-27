SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cr.cr_store_credit
FROM tpcds.catalog_returns cr
JOIN tpcds.customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE c.c_salutation = 'Mrs.'
  AND cr.cr_return_tax > 30.00
ORDER BY cr.cr_return_amount DESC
LIMIT 100
