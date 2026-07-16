SELECT sr.sr_return_quantity * sr.sr_return_amt AS total_return_value,
       CASE WHEN sr.sr_return_quantity > 39 THEN 'High' ELSE 'Low' END AS quantity_category,
       sr.sr_return_amt + sr.sr_return_tax AS amt_plus_tax,
       (sr.sr_return_amt + sr.sr_return_tax) * 1.1 AS adjusted_amount,
       r.r_reason_desc
FROM store_returns sr
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE sr.sr_return_quantity > 1
  AND sr.sr_return_amt BETWEEN 382.20 AND 347.42
