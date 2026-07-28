WITH filtered AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM tpcds.household_demographics hd
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_buy_potential IN ('>10000', '0-500')
      AND ib.ib_lower_bound >= 20000
      AND hd.hd_dep_count <= 5
)
SELECT
    hd_buy_potential,
    ib_lower_bound,
    ib_upper_bound,
    COUNT(*) AS household_count,
    AVG(hd_dep_count) AS avg_dep_count
FROM filtered
GROUP BY hd_buy_potential, ib_lower_bound, ib_upper_bound
ORDER BY household_count DESC
LIMIT 100
