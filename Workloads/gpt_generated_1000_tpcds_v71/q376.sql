WITH store_profit AS (
  SELECT
    t.t_hour AS hour,
    s.s_store_name AS channel,
    SUM(ss.ss_net_profit) AS total_net_profit,
    (
      SELECT COALESCE(SUM(sr.sr_return_amt), 0)
      FROM store_returns sr
      WHERE sr.sr_store_sk = s.s_store_sk
        AND sr.sr_return_time_sk = t.t_time_sk
    ) AS return_amount
  FROM store_sales ss
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE t.t_hour BETWEEN 8 AND 20
  GROUP BY t.t_hour, s.s_store_name, s.s_store_sk, t.t_time_sk
),
web_profit AS (
  SELECT
    t.t_hour AS hour,
    w.web_name AS channel,
    SUM(ws.ws_net_profit) AS total_net_profit,
    (
      SELECT COALESCE(SUM(wr.wr_return_amt), 0)
      FROM web_returns wr
      WHERE wr.wr_returned_time_sk = t.t_time_sk
    ) AS return_amount
  FROM web_sales ws
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  WHERE t.t_hour BETWEEN 8 AND 20
  GROUP BY t.t_hour, w.web_name, t.t_time_sk
)
SELECT hour, channel, total_net_profit, return_amount
FROM store_profit
UNION ALL
SELECT hour, channel, total_net_profit, return_amount
FROM web_profit
ORDER BY hour, channel
LIMIT 100
