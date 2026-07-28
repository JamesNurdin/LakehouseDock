WITH filtered_hd AS (
    SELECT
        hd_demo_sk,
        hd_income_band_sk,
        hd_buy_potential,
        hd_dep_count,
        hd_vehicle_count
    FROM household_demographics
    WHERE hd_dep_count BETWEEN 0 AND 9
      AND hd_vehicle_count >= 0
      AND hd_buy_potential IN ('HIGH', 'MEDIUM', 'LOW')
      AND hd_demo_sk NOT IN (10, 14)
      AND hd_income_band_sk IN (3, 8, 11, 17, 18)
      AND hd_dep_count <> 1
),
agg AS (
    SELECT
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT hd.hd_demo_sk) AS household_cnt,
        SUM(hd.hd_dep_count) AS total_dependents,
        AVG(hd.hd_vehicle_count) AS avg_vehicles,
        CASE 
            WHEN ib.ib_upper_bound >= 100000 THEN 'HIGH_INCOME'
            WHEN ib.ib_upper_bound >= 50000  THEN 'MID_INCOME'
            ELSE 'LOW_INCOME'
        END AS income_category,
        GROUPING(hd.hd_buy_potential) AS grp_buy,
        GROUPING(ib.ib_lower_bound) AS grp_lower
    FROM filtered_hd hd
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE NOT EXISTS (
        SELECT 1 FROM household_demographics hd2
        WHERE hd2.hd_demo_sk = hd.hd_demo_sk
          AND hd2.hd_vehicle_count < 0
    )
    GROUP BY GROUPING SETS (
        (hd.hd_buy_potential, ib.ib_lower_bound, ib.ib_upper_bound),
        (hd.hd_buy_potential),
        ()
    )
    HAVING COUNT(*) > 0
)
SELECT
    agg.hd_buy_potential,
    agg.ib_lower_bound,
    agg.ib_upper_bound,
    agg.household_cnt,
    agg.total_dependents,
    agg.avg_vehicles,
    agg.income_category,
    agg.grp_buy,
    agg.grp_lower,
    SUM(agg.total_dependents) OVER (
        PARTITION BY agg.hd_buy_potential
        ORDER BY agg.ib_lower_bound
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_dep
FROM agg
ORDER BY agg.hd_buy_potential ASC, agg.ib_lower_bound NULLS LAST
