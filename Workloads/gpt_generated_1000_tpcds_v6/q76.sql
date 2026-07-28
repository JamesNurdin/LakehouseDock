SELECT DISTINCT c.c_customer_id,
                cr.cr_order_number,
                cr.cr_return_amt_inc_tax
FROM   catalog_returns cr
JOIN   customer c
  ON   cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE  c.c_preferred_cust_flag = 'Y'
  AND  c.c_birth_country = 'JAPAN'
  AND  cr.cr_return_amt_inc_tax > 1000.00
LIMIT 100
