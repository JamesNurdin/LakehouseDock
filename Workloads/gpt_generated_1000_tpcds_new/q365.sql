WITH hd_sample AS (
    SELECT *
    FROM household_demographics
    TABLESAMPLE BERNOULLI (10)
    WHERE hd_buy_potential IN ('1001-5000', '>10000')
      AND hd_dep_count BETWEEN 2 AND 8
      AND hd_vehicle_count BETWEEN 1 AND 10
),
agg1 AS (
    SELECT
        hd.hd_income_band_sk,
        COUNT(*) AS hh_count,
        AVG(hd.hd_dep_count) AS avg_dep,
        SUM(hd.hd_vehicle_count) AS total_vehicles
    FROM hd_sample hd
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 50000
      AND ib.ib_upper_bound <= 200000
      AND ib.ib_income_band_sk IN (1, 3, 14, 16, 18)
    GROUP BY hd.hd_income_band_sk
),
final AS (
    SELECT
        a.hd_income_band_sk,
        a.hh_count,
        a.avg_dep,
        a.total_vehicles,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        bw.band_width,
        RANK() OVER (ORDER BY a.hh_count DESC) AS rank_by_households,
        a.hh_count * 1.0 / SUM(a.hh_count) OVER () AS pct_of_total
    FROM agg1 a
    JOIN income_band ib
        ON a.hd_income_band_sk = ib.ib_income_band_sk
    CROSS JOIN LATERAL (
        SELECT ib.ib_upper_bound - ib.ib_lower_bound AS band_width
    ) bw
    WHERE a.total_vehicles > 5
)
SELECT
    hd_income_band_sk,
    hh_count,
    avg_dep,
    total_vehicles,
    ib_lower_bound,
    ib_upper_bound,
    band_width,
    rank_by_households,
    pct_of_total
FROM final
WHERE pct_of_total > 0.05
ORDER BY rank_by_households
