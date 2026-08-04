SELECT r.r_reason_desc,
       COUNT(*) AS return_cnt,
       SUM(sr.sr_net_loss) AS total_net_loss,
       AVG(sr.sr_return_amt_inc_tax) AS avg_return_amt_inc_tax
FROM store_returns sr
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
WHERE sr.sr_return_amt_inc_tax > 100
  AND sr.sr_fee < 60
GROUP BY r.r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 10
