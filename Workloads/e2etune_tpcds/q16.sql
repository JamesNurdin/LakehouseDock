WITH hourly_stats AS (
  SELECT
    t.t_hour,
    ws.ws_web_site_sk,
    COUNT(*) AS txn_cnt,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_net_paid) AS total_paid,
    AVG(ws.ws_net_profit) AS avg_profit,
    AVG(ws.ws_net_profit / NULLIF(ws.ws_net_paid, 0)) AS avg_profit_margin
  FROM web_sales ws
  JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
  WHERE ws.ws_quantity > 1
    AND ws.ws_net_profit > 0
    AND ws.ws_web_site_sk = 1
    AND t.t_hour BETWEEN 0 AND 23
  GROUP BY t.t_hour, ws.ws_web_site_sk
)
SELECT
  t_hour,
  txn_cnt,
  total_profit,
  avg_profit,
  avg_profit_margin,
  CASE
    WHEN avg_profit_margin >= 0.5 THEN 'High'
    WHEN avg_profit_margin >= 0.3 THEN 'Medium'
    ELSE 'Low'
  END AS profit_margin_category,
  RANK() OVER (ORDER BY avg_profit DESC) AS profit_rank,
  total_profit - AVG(total_profit) OVER () AS profit_deviation,
  PERCENT_RANK() OVER (ORDER BY avg_profit DESC) AS profit_percentile
FROM hourly_stats
WHERE txn_cnt >= 10
ORDER BY profit_rank
LIMIT 5
