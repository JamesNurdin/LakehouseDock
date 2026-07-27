WITH filtered AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM tpcds.household_demographics hd
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_dep_count > 3
      AND hd.hd_vehicle_count BETWEEN 1 AND 5
      AND hd.hd_buy_potential IN ('>10000', '5001-10000', '1001-5000')
      AND hd.hd_income_band_sk IN (3, 8, 13, 16, 20)
      AND ib.ib_upper_bound <= 200000
      AND ib.ib_lower_bound >= 30000
)
SELECT
    hd_demo_sk,
    hd_income_band_sk,
    hd_buy_potential,
    hd_dep_count,
    hd_vehicle_count,
    ib_lower_bound,
    ib_upper_bound,
    CASE
        WHEN hd_buy_potential = '>10000' THEN 5
        WHEN hd_buy_potential = '5001-10000' THEN 4
        WHEN hd_buy_potential = '1001-5000' THEN 3
        WHEN hd_buy_potential = '501-1000' THEN 2
        ELSE 1
    END AS buy_potential_score,
    ROW_NUMBER() OVER (PARTITION BY hd_income_band_sk ORDER BY hd_dep_count DESC) AS rn_dep_desc,
    RANK() OVER (ORDER BY hd_vehicle_count DESC) AS vehicle_rank
FROM filtered
ORDER BY vehicle_rank, hd_demo_sk
LIMIT 100
