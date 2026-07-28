SELECT
  hd.hd_income_band_sk,
  SUM(wr.wr_return_amt) AS total_return_amount,
  COUNT(*) AS return_count
FROM web_returns AS wr
JOIN household_demographics AS hd
  ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_income_band_sk = 5
  AND wr.wr_return_quantity > 1
GROUP BY hd.hd_income_band_sk
ORDER BY total_return_amount DESC
LIMIT 100
