SELECT
    wr.wr_returned_date_sk,
    wr.wr_return_amt,
    hd.hd_income_band_sk,
    hd.hd_vehicle_count
FROM web_returns wr
JOIN household_demographics hd
  ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_income_band_sk = 16
  AND wr.wr_returned_time_sk = 78304
LIMIT 100
