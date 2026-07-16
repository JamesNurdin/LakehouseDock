WITH store_ret AS (
  SELECT
    sr.sr_store_sk,
    s.s_store_name,
    sr.sr_return_time_sk,
    sr.sr_hdemo_sk,
    sr.sr_return_amt,
    sr.sr_net_loss,
    sr.sr_return_quantity,
    'STORE' AS channel
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
),
web_ret AS (
  SELECT
    NULL AS sr_store_sk,
    'WEB' AS s_store_name,
    wr.wr_returned_time_sk AS sr_return_time_sk,
    wr.wr_returning_hdemo_sk AS sr_hdemo_sk,
    wr.wr_return_amt AS sr_return_amt,
    wr.wr_net_loss AS sr_net_loss,
    wr.wr_return_quantity,
    'WEB' AS channel
  FROM web_returns wr
),
combined AS (
  SELECT * FROM store_ret
  UNION ALL
  SELECT * FROM web_ret
)
SELECT
  c.s_store_name,
  c.channel,
  t.t_hour,
  hd.hd_income_band_sk,
  COUNT(*) AS return_cnt,
  SUM(c.sr_return_amt) AS total_return_amt,
  SUM(c.sr_net_loss) AS total_net_loss,
  AVG(c.sr_net_loss) AS avg_net_loss,
  RANK() OVER (PARTITION BY c.channel ORDER BY SUM(c.sr_net_loss) DESC) AS loss_rank
FROM combined c
JOIN time_dim t ON c.sr_return_time_sk = t.t_time_sk
JOIN household_demographics hd ON c.sr_hdemo_sk = hd.hd_demo_sk
WHERE c.sr_return_amt > 0
  AND t.t_hour BETWEEN 9 AND 21
  AND hd.hd_income_band_sk IN (1, 2, 3)
GROUP BY
  c.s_store_name,
  c.channel,
  t.t_hour,
  hd.hd_income_band_sk
ORDER BY total_net_loss DESC
LIMIT 100
