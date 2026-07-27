WITH filtered_hd_ib AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM household_demographics AS hd
    JOIN income_band AS ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_vehicle_count > 0
      AND hd.hd_dep_count <= 5
      AND ib.ib_lower_bound >= 40000
      AND ib.ib_upper_bound <= 200000
),
agg_by_band AS (
    SELECT
        hd_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        COUNT(*) AS household_cnt,
        AVG(hd_vehicle_count) AS avg_vehicle_cnt,
        AVG(hd_dep_count) AS avg_dep_cnt,
        SUM(CASE WHEN hd_buy_potential = 'HIGH' THEN 1 ELSE 0 END) AS high_potential_cnt
    FROM filtered_hd_ib
    GROUP BY hd_income_band_sk, ib_lower_bound, ib_upper_bound
)
SELECT DISTINCT
    hd_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    household_cnt,
    avg_vehicle_cnt,
    avg_dep_cnt,
    high_potential_cnt,
    RANK() OVER (ORDER BY avg_vehicle_cnt DESC) AS vehicle_cnt_rank,
    CASE
        WHEN avg_vehicle_cnt >= (SELECT AVG(hd_vehicle_count) FROM household_demographics) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS vehicle_cnt_category
FROM agg_by_band
WHERE household_cnt >= 10
  AND high_potential_cnt > 0
ORDER BY vehicle_cnt_rank
LIMIT 100
