WITH hd_stats AS (
    SELECT
        hd.hd_income_band_sk,
        COUNT(*) AS household_cnt,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt,
        SUM(CASE WHEN hd.hd_dep_count > 2 THEN 1 ELSE 0 END) AS high_dep_cnt,
        SUM(CASE WHEN hd.hd_buy_potential IN ('1001-5000', '5001-10000', '>10000') THEN 1 ELSE 0 END) AS high_buy_potential_cnt
    FROM household_demographics hd
    WHERE hd.hd_vehicle_count IS NOT NULL
    GROUP BY hd.hd_income_band_sk
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hs.household_cnt,
    hs.avg_vehicle_cnt,
    hs.high_dep_cnt,
    hs.high_buy_potential_cnt,
    (hs.high_dep_cnt / CAST(hs.household_cnt AS DOUBLE)) AS high_dep_ratio,
    (hs.high_buy_potential_cnt / CAST(hs.household_cnt AS DOUBLE)) AS high_buy_potential_ratio,
    RANK() OVER (ORDER BY hs.household_cnt DESC) AS income_band_rank
FROM hd_stats hs
JOIN income_band ib ON hs.hd_income_band_sk = ib.ib_income_band_sk
ORDER BY hs.household_cnt DESC
