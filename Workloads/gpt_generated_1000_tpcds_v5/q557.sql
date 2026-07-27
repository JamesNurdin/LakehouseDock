SELECT
  cr.cr_returning_customer_sk,
  cr.cr_return_amount,
  cr.cr_return_quantity,
  r.r_reason_desc
FROM
  catalog_returns AS cr
INNER JOIN
  reason AS r
  ON cr.cr_reason_sk = r.r_reason_sk
WHERE
  cr.cr_reversed_charge > 30.00
  AND cr.cr_returning_hdemo_sk IN (3488, 2320)
ORDER BY
  cr.cr_return_amount DESC
LIMIT 100
