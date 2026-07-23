SELECT
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(*) AS household_count,
    AVG(hd.hd_vehicle_count) AS avg_vehicle_count
FROM
    household_demographics AS hd
JOIN
    income_band AS ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    hd.hd_dep_count >= 3
    AND ib.ib_lower_bound >= 60000
    AND ib.ib_upper_bound <= 150000
GROUP BY
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY
    household_count DESC
LIMIT 100
