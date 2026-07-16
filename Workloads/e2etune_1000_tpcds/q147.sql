WITH agg AS (
    SELECT
        hd.hd_income_band_sk,
        r.r_reason_desc,
        COUNT(*) AS household_cnt,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt,
        SUM(CASE WHEN hd.hd_buy_potential = '>10000' THEN 1 ELSE 0 END) AS high_potential_cnt,
        approx_percentile(hd.hd_dep_count, 0.5) AS median_dep_cnt
    FROM household_demographics hd
    JOIN reason r
      ON true
    WHERE hd.hd_income_band_sk IN (2, 3, 4, 5)
      AND r.r_reason_id IN ('AAAAAAAABAAAAAAA', 'AAAAAAAACAAAAAAA')
    GROUP BY hd.hd_income_band_sk, r.r_reason_desc
    HAVING COUNT(*) > 10
)
SELECT
    hd_income_band_sk,
    r_reason_desc,
    household_cnt,
    avg_vehicle_cnt,
    high_potential_cnt,
    median_dep_cnt,
    RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY household_cnt DESC) AS rank_in_income_band
FROM agg
ORDER BY household_cnt DESC
LIMIT 100
