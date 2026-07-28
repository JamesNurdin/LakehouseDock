SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_store_credit) AS total_store_credit
FROM catalog_returns cr
JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE cr.cr_store_credit > 50
  AND c.c_current_addr_sk = 2664006
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY total_return_amount DESC
LIMIT 100
