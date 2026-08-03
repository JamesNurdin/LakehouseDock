SELECT r.r_reason_desc,
       COUNT(*) AS return_cnt,
       SUM(sr.sr_refunded_cash) AS total_refunded_cash
FROM tpcds.store_returns sr
JOIN tpcds.reason r
  ON sr.sr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc LIKE 'Did not like the warranty%'
  AND sr.sr_refunded_cash > 100
GROUP BY r.r_reason_desc
ORDER BY total_refunded_cash DESC
LIMIT 10
