SELECT cr.cr_return_amount,
       cr.cr_return_quantity,
       cu.c_email_address
FROM   catalog_returns cr
JOIN   customer cu
       ON cr.cr_refunded_customer_sk = cu.c_customer_sk
WHERE  cr.cr_return_quantity > 10
  AND  cu.c_email_address LIKE '%@org'
