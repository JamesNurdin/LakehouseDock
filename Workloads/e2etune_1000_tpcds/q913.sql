WITH per_page AS (
  SELECT
    wr_reason_sk,
    wr_web_page_sk,
    COUNT(*) AS returns_cnt,
    SUM(wr_net_loss) AS net_loss,
    SUM(wr_reversed_charge) AS reversed_charge,
    SUM(wr_return_amt) AS return_amount
  FROM web_returns
  WHERE wr_net_loss > 400
  GROUP BY wr_reason_sk, wr_web_page_sk
),
per_reason AS (
  SELECT
    wr_reason_sk,
    COUNT(*) AS total_returns,
    SUM(wr_net_loss) AS total_net_loss,
    SUM(wr_reversed_charge) AS total_rev_charge,
    AVG(wr_return_quantity) AS avg_quantity
  FROM web_returns
  WHERE wr_net_loss > 400
  GROUP BY wr_reason_sk
)
SELECT
  r.r_reason_desc,
  r.r_reason_id,
  pp.wr_web_page_sk AS web_page_sk,
  pp.returns_cnt,
  pp.net_loss,
  pp.reversed_charge,
  pp.return_amount,
  pr.total_returns,
  pr.total_net_loss,
  pr.total_rev_charge,
  pr.avg_quantity,
  RANK() OVER (PARTITION BY r.r_reason_id ORDER BY pp.net_loss DESC) AS page_net_loss_rank
FROM per_page pp
JOIN per_reason pr ON pp.wr_reason_sk = pr.wr_reason_sk
JOIN reason r ON pp.wr_reason_sk = r.r_reason_sk
WHERE pp.returns_cnt >= 5
ORDER BY r.r_reason_desc, page_net_loss_rank
LIMIT 100
