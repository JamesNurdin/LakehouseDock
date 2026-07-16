WITH agg AS (
    SELECT
        td.t_meal_time,
        hd.hd_income_band_sk,
        COUNT(*) AS household_cnt,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt,
        SUM(CASE WHEN hd.hd_buy_potential = '>10000' THEN 1 ELSE 0 END) AS high_buy_potential_cnt,
        APPROX_PERCENTILE(hd.hd_vehicle_count, 0.5) AS median_vehicle_cnt
    FROM household_demographics hd
    JOIN time_dim td ON 1 = 1
    WHERE td.t_meal_time IN ('breakfast', 'lunch')
      AND hd.hd_income_band_sk IN (3, 4, 5)
      AND hd.hd_buy_potential <> '0-500'
    GROUP BY td.t_meal_time, hd.hd_income_band_sk
)
SELECT
    t_meal_time,
    hd_income_band_sk,
    household_cnt,
    avg_vehicle_cnt,
    high_buy_potential_cnt,
    median_vehicle_cnt,
    RANK() OVER (PARTITION BY t_meal_time ORDER BY avg_vehicle_cnt DESC) AS vehicle_cnt_rank
FROM agg
WHERE household_cnt > 10
ORDER BY t_meal_time, vehicle_cnt_rank
LIMIT 50
