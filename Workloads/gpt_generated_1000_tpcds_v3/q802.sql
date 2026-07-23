WITH wr_agg AS (
    SELECT
        wr_refunded_hdemo_sk AS hd_demo_sk,
        COUNT(*) AS return_cnt,
        SUM(wr_return_amt) AS total_return_amt,
        AVG(wr_fee) AS avg_fee,
        SUM(CASE WHEN wr_fee > 20 THEN wr_fee ELSE 0 END) AS high_fee_total
    FROM web_returns
    WHERE wr_fee > 10.00
      AND wr_returned_time_sk BETWEEN 20000 AND 60000
      AND wr_return_quantity >= 1
    GROUP BY wr_refunded_hdemo_sk
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE WHEN hd.hd_vehicle_count >= 3 THEN '3+ Vehicles'
         WHEN hd.hd_vehicle_count = 2 THEN '2 Vehicles'
         ELSE '0-1 Vehicles' END AS vehicle_category,
    COUNT(DISTINCT hd.hd_demo_sk) AS household_cnt,
    SUM(wr_agg.return_cnt) AS total_returns,
    SUM(wr_agg.total_return_amt) AS total_return_amount,
    AVG(wr_agg.avg_fee) AS avg_fee_across_households,
    MAX(wr_agg.high_fee_total) AS max_high_fee_total
FROM wr_agg
JOIN household_demographics hd
    ON hd.hd_demo_sk = wr_agg.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_vehicle_count >= 2
  AND ib.ib_lower_bound >= 40000
  AND ib.ib_upper_bound <= 200000
GROUP BY
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE WHEN hd.hd_vehicle_count >= 3 THEN '3+ Vehicles'
         WHEN hd.hd_vehicle_count = 2 THEN '2 Vehicles'
         ELSE '0-1 Vehicles' END
ORDER BY total_return_amount DESC
LIMIT 100
