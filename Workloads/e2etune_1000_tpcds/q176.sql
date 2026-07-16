WITH hd_agg AS (
    SELECT
        hd_income_band_sk,
        COUNT(*) AS household_cnt,
        AVG(hd_vehicle_count) AS avg_vehicle_cnt,
        SUM(hd_dep_count) AS total_dep_cnt,
        COUNT(DISTINCT hd_demo_sk) AS distinct_demo_cnt
    FROM household_demographics
    WHERE hd_vehicle_count > 0
    GROUP BY hd_income_band_sk
),
income_info AS (
    SELECT
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        CASE WHEN ib_lower_bound >= 100000 THEN 'High' ELSE 'Low' END AS income_category
    FROM income_band
)
SELECT
    i.income_category,
    i.ib_lower_bound,
    i.ib_upper_bound,
    h.household_cnt,
    h.avg_vehicle_cnt,
    h.total_dep_cnt,
    h.distinct_demo_cnt,
    (h.avg_vehicle_cnt * h.total_dep_cnt) AS vehicle_dep_product,
    RANK() OVER (ORDER BY h.household_cnt DESC) AS household_cnt_rank
FROM hd_agg h
JOIN income_info i
    ON h.hd_income_band_sk = i.ib_income_band_sk
WHERE i.income_category = 'High'
ORDER BY household_cnt_rank
LIMIT 100
