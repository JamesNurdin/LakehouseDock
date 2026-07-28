WITH wr_agg AS (
    SELECT
        wr_refunded_hdemo_sk AS hd_demo_sk,
        COUNT(*) AS returns_cnt,
        SUM(wr_return_amt) AS total_return_amt,
        AVG(wr_fee) AS avg_fee,
        MIN(wr_return_amt) AS min_return_amt,
        MAX(wr_return_amt) AS max_return_amt
    FROM web_returns
    WHERE wr_return_amt > 100.00
    GROUP BY wr_refunded_hdemo_sk
)
SELECT
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(agg.returns_cnt) AS total_returns,
    SUM(agg.total_return_amt) AS total_return_amount,
    AVG(agg.avg_fee) AS avg_fee_per_demo,
    MIN(agg.min_return_amt) AS min_return_amount,
    MAX(agg.max_return_amt) AS max_return_amount,
    MAX(lateral_max.max_return_amt) AS max_return_amt_per_demo
FROM wr_agg agg
JOIN household_demographics hd
    ON agg.hd_demo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
CROSS JOIN LATERAL (
    SELECT MAX(wr_return_amt) AS max_return_amt
    FROM web_returns wr
    WHERE wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
      AND wr.wr_fee > 50.00
) AS lateral_max
WHERE hd.hd_vehicle_count >= 2
  AND hd.hd_buy_potential = '>10000'
  AND ib.ib_lower_bound >= 120000
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_refunded_hdemo_sk = hd.hd_demo_sk
          AND wr2.wr_return_tax > 20.00
  )
GROUP BY
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY total_return_amount DESC
LIMIT 100
