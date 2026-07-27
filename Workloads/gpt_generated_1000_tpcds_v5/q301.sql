SELECT
  c.c_customer_id,
  SUM(cr.cr_return_amount) AS total_return_amount,
  COUNT(*) AS return_cnt
FROM
  catalog_returns AS cr
JOIN
  customer AS c
  ON cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE
  cr.cr_reversed_charge > 50.00
  AND c.c_last_review_date BETWEEN 2452300 AND 2452600
GROUP BY
  c.c_customer_id
ORDER BY
  total_return_amount DESC
LIMIT 100
