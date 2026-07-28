SELECT
    d.d_year,
    d.d_month_seq,
    SUM(sr.sr_refunded_cash) AS total_refunded_cash,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
FROM store_returns sr
JOIN date_dim d
  ON sr.sr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND sr.sr_refunded_cash > 100
GROUP BY d.d_year, d.d_month_seq
ORDER BY d.d_year, d.d_month_seq
