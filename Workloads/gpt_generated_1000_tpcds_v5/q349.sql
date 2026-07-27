WITH filtered_returns AS (
  SELECT
    sr.sr_return_time_sk,
    sr.sr_hdemo_sk,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    sr.sr_net_loss
  FROM store_returns sr
  JOIN time_dim td
    ON sr.sr_return_time_sk = td.t_time_sk
  JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
  WHERE td.t_am_pm = 'PM'
    AND td.t_minute BETWEEN 5 AND 15
    AND sr.sr_return_amt > 0
    AND hd.hd_dep_count <= 4
    AND sr.sr_return_quantity > 1
)
SELECT
  COALESCE(ib.ib_lower_bound, -1) AS income_lower_bound,
  COALESCE(ib.ib_upper_bound, -1) AS income_upper_bound,
  COUNT(*) AS return_cnt,
  SUM(fr.sr_return_amt) AS total_return_amount,
  AVG(fr.sr_return_quantity) AS avg_return_quantity,
  MIN(fr.sr_net_loss) AS min_net_loss,
  MAX(fr.sr_net_loss) AS max_net_loss
FROM filtered_returns fr
JOIN household_demographics hd
  ON fr.sr_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY
  COALESCE(ib.ib_lower_bound, -1),
  COALESCE(ib.ib_upper_bound, -1)
ORDER BY total_return_amount DESC
LIMIT 100
