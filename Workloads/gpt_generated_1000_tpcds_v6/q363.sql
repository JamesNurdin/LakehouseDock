SELECT DISTINCT
  cr.cr_order_number,
  cr.cr_return_quantity,
  cr.cr_return_amount,
  r.r_reason_desc
FROM catalog_returns AS cr
JOIN reason AS r
  ON cr.cr_reason_sk = r.r_reason_sk
WHERE cr.cr_reversed_charge > 100
  AND r.r_reason_desc LIKE '%service%'
LIMIT 100
