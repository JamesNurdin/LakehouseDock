WITH hd_agg AS (
    SELECT hd_income_band_sk,
           AVG(hd_vehicle_count) AS avg_vehicle_count,
           COUNT(*) AS household_cnt
    FROM household_demographics
    WHERE hd_income_band_sk IN (10, 13, 14)
      AND hd_dep_count >= 2
    GROUP BY hd_income_band_sk
),
wh_agg AS (
    SELECT w_state,
           w_street_type,
           COUNT(*) AS warehouse_cnt
    FROM warehouse
    WHERE w_state IN ('TN', 'MI', 'AL')
      AND w_street_type IN ('Ave', 'St')
    GROUP BY w_state, w_street_type
)
SELECT hd_agg.hd_income_band_sk,
       hd_agg.avg_vehicle_count,
       hd_agg.household_cnt,
       wh_agg.w_state,
       wh_agg.w_street_type,
       wh_agg.warehouse_cnt
FROM hd_agg
CROSS JOIN wh_agg
ORDER BY hd_agg.hd_income_band_sk, wh_agg.w_state
