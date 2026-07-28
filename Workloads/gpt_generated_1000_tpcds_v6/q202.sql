SELECT
    cr.cr_order_number,
    cr.cr_refunded_cash,
    cr.cr_return_amount,
    r.r_reason_desc
FROM catalog_returns AS cr
JOIN reason AS r
  ON cr.cr_reason_sk = r.r_reason_sk
WHERE cr.cr_refunded_cash > 1000
  AND r.r_reason_id = 'AAAAAAAAMAAAAAAA'
LIMIT 100
