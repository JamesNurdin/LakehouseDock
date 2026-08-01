SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_refunded_cash,
    r.r_reason_desc
FROM catalog_returns AS cr
JOIN reason AS r
    ON cr.cr_reason_sk = r.r_reason_sk
WHERE cr.cr_refunded_cash > 200
  AND cr.cr_return_amount < 500
ORDER BY cr.cr_return_amount DESC
LIMIT 100
