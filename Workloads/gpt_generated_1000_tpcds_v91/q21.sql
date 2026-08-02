SELECT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(*) AS return_count
FROM tpcds.catalog_returns cr
JOIN tpcds.customer c
  ON cr.cr_returning_customer_sk = c.c_customer_sk
WHERE cr.cr_returning_addr_sk = 2234491
  AND c.c_salutation = 'Mr.'
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY total_return_amount DESC
