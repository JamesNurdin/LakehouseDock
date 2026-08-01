SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_fee,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name
FROM tpcds.catalog_returns AS cr
JOIN tpcds.customer AS c
  ON cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE cr.cr_fee > 30
  AND c.c_salutation = 'Mr.'
LIMIT 100
