SELECT s.s_store_id,
       r.r_reason_desc,
       SUM(sr.sr_net_loss) AS total_net_loss,
       SUM(sr.sr_refunded_cash) AS total_refunded_cash,
       CASE
         WHEN SUM(sr.sr_net_loss) > 10000 THEN 'High Impact'
         WHEN SUM(sr.sr_net_loss) > 1000 THEN 'Medium Impact'
         ELSE 'Low Impact'
       END AS impact_level,
       DENSE_RANK() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(sr.sr_net_loss) DESC) AS loss_rank_per_store
FROM store s
JOIN store_returns sr ON s.s_store_sk = sr.sr_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
GROUP BY s.s_store_id, s.s_store_sk, r.r_reason_desc
HAVING SUM(sr.sr_net_loss) > 0
ORDER BY s.s_store_id, loss_rank_per_store
