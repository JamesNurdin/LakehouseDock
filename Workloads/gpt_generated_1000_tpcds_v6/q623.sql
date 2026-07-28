SELECT DISTINCT r.r_reason_desc,
       cr.cr_refunded_cash
FROM   catalog_returns cr
JOIN   reason r
  ON   cr.cr_reason_sk = r.r_reason_sk
WHERE  cr.cr_refunded_cash > 500.00
  AND  cr.cr_returning_customer_sk = 11202515
ORDER BY r.r_reason_desc
LIMIT 100
