WITH filtered AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM tpcds.household_demographics AS hd
    JOIN tpcds.income_band AS ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_buy_potential = '1001-5000'
      AND hd.hd_dep_count >= 2
      AND ib.ib_upper_bound <= 110000
)
SELECT
    hd_buy_potential,
    ib_lower_bound,
    ib_upper_bound,
    COUNT(DISTINCT hd_demo_sk) AS household_cnt,
    AVG(hd_vehicle_count) AS avg_vehicle_cnt,
    SUM(hd_dep_count) AS total_dep_cnt,
    MIN(ib_lower_bound) AS min_income_lower,
    MAX(ib_upper_bound) AS max_income_upper
FROM filtered
GROUP BY hd_buy_potential, ib_lower_bound, ib_upper_bound
ORDER BY household_cnt DESC
LIMIT 10
