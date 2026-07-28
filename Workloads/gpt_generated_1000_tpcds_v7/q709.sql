SELECT ib_lower_bound,
       ib_upper_bound,
       avg_vehicle_count,
       total_dependents,
       group_label
FROM (
    SELECT ib.ib_lower_bound,
           ib.ib_upper_bound,
           AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
           SUM(hd.hd_dep_count) AS total_dependents,
           'valid' AS group_label
    FROM household_demographics AS hd
    JOIN income_band AS ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_vehicle_count >= 0
      AND hd.hd_buy_potential <> 'Unknown'
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound

    UNION ALL

    SELECT ib.ib_lower_bound,
           ib.ib_upper_bound,
           AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
           SUM(hd.hd_dep_count) AS total_dependents,
           'unknown' AS group_label
    FROM household_demographics AS hd
    JOIN income_band AS ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_vehicle_count = -1
      AND hd.hd_buy_potential = 'Unknown'
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
) AS combined
LIMIT 100
