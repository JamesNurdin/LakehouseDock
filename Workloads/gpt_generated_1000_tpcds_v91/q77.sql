SELECT DISTINCT s.s_store_id AS store_id, r.r_reason_desc AS reason_desc
FROM store_returns sr
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
WHERE s.s_rec_start_date >= DATE '2000-01-01'
  AND t.t_am_pm = 'AM'
  AND sr.sr_refunded_cash > 500
  AND EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_store_sk = s.s_store_sk
      AND sr2.sr_return_amt_inc_tax > 1000
  )
EXCEPT
SELECT DISTINCT s.s_store_id AS store_id, r.r_reason_desc AS reason_desc
FROM store_returns sr
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
WHERE s.s_rec_start_date >= DATE '2000-01-01'
  AND t.t_am_pm = 'PM'
  AND sr.sr_refunded_cash > 500
  AND EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_store_sk = s.s_store_sk
      AND sr2.sr_return_amt_inc_tax > 1000
  )
ORDER BY store_id, reason_desc
