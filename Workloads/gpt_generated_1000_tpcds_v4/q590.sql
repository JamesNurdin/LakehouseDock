WITH hd_agg AS (
    SELECT
        ib.ib_income_band_sk AS income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE
            WHEN hd.hd_buy_potential LIKE '0-%' THEN 'Low'
            WHEN hd.hd_buy_potential LIKE '1001-5000' THEN 'Medium'
            ELSE 'High'
        END AS buy_potential_category,
        COUNT(*) AS households,
        AVG(hd.hd_dep_count) AS avg_dependents,
        SUM(hd.hd_vehicle_count) AS total_vehicles
    FROM tpcds.household_demographics hd
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_dep_count >= 1
      AND hd.hd_vehicle_count >= 1
      AND ib.ib_lower_bound >= 30000
      AND ib.ib_upper_bound <= 120000
      AND hd.hd_buy_potential <> 'Unknown'
    GROUP BY
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE
            WHEN hd.hd_buy_potential LIKE '0-%' THEN 'Low'
            WHEN hd.hd_buy_potential LIKE '1001-5000' THEN 'Medium'
            ELSE 'High'
        END
)
SELECT
    buy_potential_category,
    SUM(households) AS total_households,
    AVG(avg_dependents) AS avg_dependents_across_bands,
    SUM(total_vehicles) AS total_vehicles,
    MIN(ib_lower_bound) AS min_income_lower,
    MAX(ib_upper_bound) AS max_income_upper
FROM hd_agg
GROUP BY buy_potential_category
HAVING SUM(households) > 100
ORDER BY total_households DESC
LIMIT 100
