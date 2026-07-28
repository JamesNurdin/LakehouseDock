SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    r.r_reason_desc
FROM tpcds.catalog_returns AS cr
JOIN tpcds.reason AS r
  ON cr.cr_reason_sk = r.r_reason_sk
WHERE cr.cr_store_credit > 100
  AND r.r_reason_id = 'AAAAAAAAABAAAAAA'
LIMIT 100
