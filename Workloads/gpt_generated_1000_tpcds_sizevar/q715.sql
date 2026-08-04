SELECT
  cr.cr_return_amount,
  cr.cr_return_tax,
  c.c_first_name,
  c.c_last_name
FROM catalog_returns AS cr
JOIN customer AS c
  ON cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE cr.cr_warehouse_sk = 16
  AND c.c_birth_month = 4
