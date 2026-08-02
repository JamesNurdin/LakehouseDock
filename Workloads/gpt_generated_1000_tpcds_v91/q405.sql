WITH agg AS (
    SELECT
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(*) AS household_cnt,
        SUM(hd.hd_dep_count) AS total_dep_cnt,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt
    FROM household_demographics hd
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_dep_count >= 2
        AND hd.hd_vehicle_count >= 0
        AND hd.hd_buy_potential IN ('>10000', '5001-10000')
        AND ib.ib_lower_bound > 50000
        AND ib.ib_upper_bound <= 200000
        AND hd.hd_income_band_sk NOT IN (
            SELECT ib_income_band_sk
            FROM income_band
            WHERE ib_upper_bound > 180000
        )
        AND hd.hd_vehicle_count <> -1
    GROUP BY hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
filtered AS (
    SELECT
        hd_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        household_cnt,
        total_dep_cnt,
        avg_vehicle_cnt
    FROM agg
    WHERE total_dep_cnt > (SELECT AVG(total_dep_cnt) FROM agg)
        AND household_cnt >= 5
        AND avg_vehicle_cnt > 1.5
)
SELECT
    f.hd_income_band_sk,
    f.ib_lower_bound,
    f.ib_upper_bound,
    f.household_cnt,
    f.total_dep_cnt,
    f.avg_vehicle_cnt
FROM filtered f
WHERE f.household_cnt >= 10
EXCEPT
SELECT
    a.hd_income_band_sk,
    a.ib_lower_bound,
    a.ib_upper_bound,
    a.household_cnt,
    a.total_dep_cnt,
    a.avg_vehicle_cnt
FROM agg a
WHERE a.total_dep_cnt < 20
ORDER BY total_dep_cnt DESC
