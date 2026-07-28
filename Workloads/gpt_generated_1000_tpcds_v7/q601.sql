SELECT
    wr.wr_return_amt,
    hd.hd_income_band_sk,
    hd.hd_vehicle_count
FROM web_returns AS wr
JOIN household_demographics AS hd
  ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_dep_count = 0
  AND wr.wr_return_quantity > 5
