SELECT
  c.c_customer_id,
  cr.cr_order_number,
  cr.cr_return_amount,
  cr.cr_returned_date_sk
FROM catalog_returns cr
JOIN customer c
  ON cr.cr_returning_customer_sk = c.c_customer_sk
WHERE cr.cr_return_amount > 1000
  AND c.c_first_sales_date_sk = 2451393
ORDER BY cr.cr_return_amount DESC
LIMIT 100
