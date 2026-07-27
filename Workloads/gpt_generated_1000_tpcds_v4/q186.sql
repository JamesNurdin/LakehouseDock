WITH base AS (
   SELECT
       sr.sr_store_sk,
       r.r_reason_desc,
       SUM(sr.sr_net_loss) AS total_net_loss,
       COUNT(*) AS return_cnt,
       AVG(sr.sr_return_amt_inc_tax) AS avg_return_amt
   FROM store_returns sr
   JOIN reason r
     ON sr.sr_reason_sk = r.r_reason_sk
   WHERE sr.sr_return_amt_inc_tax > 100.00
     AND sr.sr_return_ship_cost < 300.00
     AND sr.sr_refunded_cash BETWEEN 50 AND 2000
     AND r.r_reason_desc NOT LIKE '%color%'
     AND EXISTS (
         SELECT 1
         FROM reason r2
         WHERE r2.r_reason_sk = sr.sr_reason_sk
           AND r2.r_reason_id = 'AAAAAAAJAAAAAAA'
     )
   GROUP BY sr.sr_store_sk, r.r_reason_desc
)
SELECT
   DISTINCT base.sr_store_sk,
   base.r_reason_desc,
   base.total_net_loss,
   base.return_cnt,
   base.avg_return_amt,
   RANK() OVER (ORDER BY base.total_net_loss DESC) AS loss_rank
FROM base
ORDER BY loss_rank
LIMIT 100
