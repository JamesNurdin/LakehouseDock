WITH agg_by_band AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(hd.hd_demo_sk) AS household_cnt,
        SUM(COALESCE(hd.hd_dep_count, 0)) AS total_dep,
        AVG(hd.hd_vehicle_count) AS avg_vehicle,
        COUNT(DISTINCT CASE WHEN regexp_like(hd.hd_buy_potential, '^high.*') THEN hd.hd_buy_potential END) AS high_potential_cnt
    FROM household_demographics hd
    RIGHT OUTER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
),
distinct_buy AS (
    SELECT DISTINCT
        hd.hd_income_band_sk,
        regexp_extract(hd.hd_buy_potential, '([A-Za-z]+)', 1) AS buy_potential_word,
        CASE
            WHEN hd.hd_buy_potential LIKE '%low%' THEN 'LOW'
            WHEN hd.hd_buy_potential LIKE '%medium%' THEN 'MEDIUM'
            ELSE 'OTHER'
        END AS buy_category
    FROM household_demographics hd
    WHERE hd.hd_buy_potential IS NOT NULL
)
SELECT
    COALESCE(agg.ib_income_band_sk, db.hd_income_band_sk) AS income_band_sk,
    agg.ib_lower_bound,
    agg.ib_upper_bound,
    agg.household_cnt,
    agg.total_dep,
    agg.avg_vehicle,
    db.buy_category,
    db.buy_potential_word,
    (SELECT AVG(hd2.hd_vehicle_count) FROM household_demographics hd2) AS overall_avg_vehicle
FROM agg_by_band agg
FULL OUTER JOIN distinct_buy db
    ON agg.ib_income_band_sk = db.hd_income_band_sk
ORDER BY agg.household_cnt DESC, agg.ib_lower_bound ASC
LIMIT 100
