SELECT DISTINCT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cr.cr_return_amount,
    cr.cr_reason_sk
FROM catalog_returns cr
JOIN customer c
  ON cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE cr.cr_reason_sk IN (45, 51, 56)
  AND cr.cr_store_credit > 50
ORDER BY c.c_last_name ASC, c.c_first_name ASC
LIMIT 100
