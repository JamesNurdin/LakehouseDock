WITH joined AS (
    SELECT
        ib.ib_income_band_sk AS ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        wr.wr_net_loss,
        wr.wr_return_amt_inc_tax,
        hd.hd_dep_count,
        hd.hd_vehicle_count
    FROM web_returns wr
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE wr.wr_return_amt_inc_tax > 0
      AND wr.wr_net_loss IS NOT NULL
      AND hd.hd_dep_count BETWEEN 1 AND 7
      AND hd.hd_vehicle_count >= -1
      AND ib.ib_lower_bound >= 50000
),
agg AS (
    SELECT
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        SUM(wr_net_loss) AS total_net_loss,
        AVG(wr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
        COUNT(*) AS cnt_returns,
        AVG(hd_dep_count) AS avg_dep_count,
        AVG(hd_vehicle_count) AS avg_vehicle_count
    FROM joined
    GROUP BY ib_income_band_sk, ib_lower_bound, ib_upper_bound
)
SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    total_net_loss,
    avg_return_amt_inc_tax,
    cnt_returns,
    avg_dep_count,
    avg_vehicle_count
FROM agg
WHERE total_net_loss > 1000
  AND avg_return_amt_inc_tax > 100
  AND cnt_returns >= 10
  AND avg_dep_count BETWEEN 2 AND 5
  AND avg_vehicle_count >= 0
ORDER BY total_net_loss DESC
LIMIT 100
