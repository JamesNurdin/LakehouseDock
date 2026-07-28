SELECT DISTINCT r.r_reason_desc,
                w.wr_refunded_cash
FROM tpcds.web_returns AS w
JOIN tpcds.reason AS r
  ON w.wr_reason_sk = r.r_reason_sk
WHERE r.r_reason_id = 'AAAAAAAAABAAAAAA'
  AND w.wr_refunded_cash > 500
ORDER BY w.wr_refunded_cash DESC
LIMIT 20
