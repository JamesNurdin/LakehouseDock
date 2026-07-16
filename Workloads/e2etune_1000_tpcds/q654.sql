SELECT
    td.t_hour,
    td.t_shift,
    sr.sr_store_sk,
    COUNT(*) AS return_cnt,
    SUM(sr.sr_return_quantity) AS total_qty,
    SUM(sr.sr_return_amt) AS total_return_amt,
    SUM(sr.sr_refunded_cash) AS total_refunded_cash,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_tax) AS avg_return_tax,
    COUNT(DISTINCT sr.sr_item_sk) AS distinct_items,
    (SUM(CASE WHEN sr.sr_fee > 0 THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS pct_with_fee,
    SUM(sr.sr_net_loss) / COUNT(*) AS avg_net_loss_per_return
FROM store_returns sr
JOIN time_dim td
  ON sr.sr_return_time_sk = td.t_time_sk
WHERE sr.sr_store_sk IN (176, 466, 751)
  AND sr.sr_item_sk IN (96650, 118185, 92064)
  AND sr.sr_return_quantity > 1
  AND td.t_hour BETWEEN 9 AND 17
  AND td.t_am_pm = 'PM'
GROUP BY td.t_hour, td.t_shift, sr.sr_store_sk
HAVING SUM(sr.sr_return_amt) > 1000
ORDER BY total_return_amt DESC
LIMIT 50
