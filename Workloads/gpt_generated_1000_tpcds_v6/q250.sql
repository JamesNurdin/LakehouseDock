WITH
  store_agg AS (
    SELECT
      r.r_reason_desc,
      'store' AS channel,
      COUNT(*) AS return_cnt,
      SUM(sr.sr_return_quantity) AS total_qty,
      SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_quantity > 10
    GROUP BY ROLLUP(r.r_reason_desc)
  ),
  web_agg AS (
    SELECT
      r.r_reason_desc,
      'web' AS channel,
      COUNT(*) AS return_cnt,
      SUM(wr.wr_return_quantity) AS total_qty,
      SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_ship_cost > 100
    GROUP BY ROLLUP(r.r_reason_desc)
  ),
  combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
  ),
  avg_loss AS (
    SELECT AVG(t.total_net_loss) AS avg_net_loss FROM (
      SELECT SUM(sr.sr_net_loss) AS total_net_loss FROM store_returns sr
      UNION ALL
      SELECT SUM(wr.wr_net_loss) AS total_net_loss FROM web_returns wr
    ) t
  )
SELECT
  c.r_reason_desc,
  c.channel,
  CASE
    WHEN c.total_net_loss > a.avg_net_loss THEN 'Above Avg'
    ELSE 'Below Avg'
  END AS loss_vs_avg,
  c.return_cnt,
  c.total_qty,
  c.total_net_loss
FROM combined c
CROSS JOIN avg_loss a
WHERE c.return_cnt IS NOT NULL
ORDER BY c.r_reason_desc ASC, c.channel, loss_vs_avg
LIMIT 100
