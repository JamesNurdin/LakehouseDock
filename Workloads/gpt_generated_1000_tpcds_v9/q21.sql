SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT hd.hd_demo_sk) AS distinct_household_count
FROM
    household_demographics hd
JOIN
    income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    hd.hd_vehicle_count >= 2
    AND ib.ib_lower_bound >= 50000
GROUP BY
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY
    distinct_household_count DESC
LIMIT 100
