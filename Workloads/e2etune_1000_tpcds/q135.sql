WITH returns_by_time AS (
  SELECT
    td.t_hour,
    td.t_shift,
    COUNT(*) AS return_cnt,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt) AS avg_return_amt
  FROM web_returns wr
  JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
  WHERE wr.wr_return_amt > 0
    AND td.t_hour BETWEEN 8 AND 20
  GROUP BY td.t_hour, td.t_shift
  HAVING SUM(wr.wr_return_amt) > 1000
)
SELECT
  rbt.t_hour,
  rbt.t_shift,
  rbt.return_cnt,
  rbt.total_return_amt,
  rbt.total_net_loss,
  rbt.avg_return_amt,
  RANK() OVER (ORDER BY rbt.total_net_loss DESC) AS net_loss_rank,
  (SELECT AVG(cc_tax_percentage) FROM call_center WHERE cc_state = 'TN') AS avg_tax_tn
FROM returns_by_time rbt
ORDER BY rbt.total_net_loss DESC
LIMIT 50
