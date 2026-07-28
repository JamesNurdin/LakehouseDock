WITH hd_income_summary AS (
    SELECT
        hd.hd_income_band_sk AS income_band_sk,
        ib.ib_lower_bound AS lower_bound,
        ib.ib_upper_bound AS upper_bound,
        hd.hd_buy_potential AS buy_potential,
        SUM(hd.hd_dep_count) AS total_dep,
        AVG(hd.hd_vehicle_count) AS avg_vehicle,
        COUNT(*) AS household_cnt
    FROM tpcds.household_demographics AS hd
    JOIN tpcds.income_band AS ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_dep_count BETWEEN 2 AND 9
      AND hd.hd_vehicle_count >= 0
      AND hd.hd_buy_potential IN ('5001-10000', '1001-5000', '501-1000')
      AND ib.ib_lower_bound >= 0
      AND ib.ib_upper_bound <= 200000
      AND hd.hd_income_band_sk NOT IN (0)
    GROUP BY
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential
)
SELECT
    buy_potential,
    AVG(total_dep) AS avg_total_dep,
    SUM(avg_vehicle) AS sum_avg_vehicle,
    COUNT(*) AS num_income_groups,
    SUM(household_cnt) AS total_households
FROM hd_income_summary
WHERE total_dep > 5
  AND avg_vehicle < 3
GROUP BY buy_potential
HAVING SUM(household_cnt) > 10
ORDER BY avg_total_dep DESC
LIMIT 10
