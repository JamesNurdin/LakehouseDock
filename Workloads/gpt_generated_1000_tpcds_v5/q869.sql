WITH filtered_hd AS (
    SELECT DISTINCT
        hd_demo_sk,
        hd_income_band_sk,
        hd_buy_potential,
        hd_dep_count,
        hd_vehicle_count
    FROM household_demographics
    WHERE hd_dep_count BETWEEN 1 AND 5
      AND hd_vehicle_count >= 0
      AND hd_buy_potential IN ('5001-10000', '>10000')
),
filtered_income AS (
    SELECT ib_income_band_sk,
           ib_lower_bound,
           ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound >= 50001
      AND ib_upper_bound <= 160000
)
SELECT
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(wr.wr_order_number) AS return_cnt,
    SUM(wr.wr_return_amt) AS total_return_amt,
    AVG(wr.wr_return_tax) AS avg_return_tax,
    MIN(wr.wr_return_ship_cost) AS min_ship_cost,
    MAX(wr.wr_return_ship_cost) AS max_ship_cost
FROM filtered_hd hd
JOIN filtered_income ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_returns wr
  ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE wr.wr_return_ship_cost > 100.00
  AND wr.wr_return_tax BETWEEN 2.0 AND 30.0
  AND EXISTS (
        SELECT 1
        FROM household_demographics hd_ret
        WHERE hd_ret.hd_demo_sk = wr.wr_returning_hdemo_sk
          AND hd_ret.hd_vehicle_count <= 2
          AND hd_ret.hd_dep_count = 0
      )
GROUP BY
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound
HAVING COUNT(wr.wr_order_number) > 10
ORDER BY total_return_amt DESC
LIMIT 100
