WITH reason_agg AS (
  SELECT r.r_reason_desc AS reason_desc,
         COUNT(*) AS num_returns,
         SUM(wr.wr_return_amt) AS total_return_amount,
         AVG(wr.wr_return_amt) AS avg_return_amount,
         SUM(wr.wr_net_loss) AS total_net_loss
  FROM web_returns wr
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE wr.wr_returned_date_sk BETWEEN 2450900 AND 2451100
    AND wr.wr_return_quantity > 0
  GROUP BY r.r_reason_desc
  HAVING SUM(wr.wr_return_amt) > 1000
)
SELECT ra.reason_desc,
       ra.num_returns,
       ra.total_return_amount,
       ra.avg_return_amount,
       ra.total_net_loss,
       ra.total_return_amount / SUM(ra.total_return_amount) OVER () AS pct_of_total_return,
       RANK() OVER (ORDER BY ra.total_return_amount DESC) AS return_amount_rank
FROM reason_agg ra
ORDER BY ra.total_return_amount DESC
LIMIT 10
