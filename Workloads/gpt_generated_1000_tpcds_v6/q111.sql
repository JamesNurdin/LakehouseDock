WITH hb AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        regexp_extract(hd.hd_buy_potential, '^([0-9]+)', 1) AS buy_pot_low,
        regexp_extract(hd.hd_buy_potential, '([0-9]+)$', 1) AS buy_pot_high,
        CASE
            WHEN regexp_like(hd.hd_buy_potential, '^>') THEN concat('Above ', substr(hd.hd_buy_potential, 2))
            WHEN regexp_like(hd.hd_buy_potential, '-') THEN concat('Between ', regexp_extract(hd.hd_buy_potential, '^([0-9]+)', 1), ' and ', regexp_extract(hd.hd_buy_potential, '([0-9]+)$', 1))
            ELSE 'Unknown'
        END AS buy_pot_desc
    FROM tpcds.household_demographics hd
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_buy_potential LIKE '%-%' OR hd.hd_buy_potential LIKE '>%%'
),
avg_vehicle_per_band AS (
    SELECT
        hd_income_band_sk AS ib_income_band_sk,
        AVG(hd_vehicle_count) AS avg_vehicle_cnt
    FROM tpcds.household_demographics
    GROUP BY hd_income_band_sk
)
SELECT
    hb.ib_income_band_sk,
    hb.ib_lower_bound,
    hb.ib_upper_bound,
    hb.buy_pot_desc,
    COUNT(*) AS household_cnt,
    AVG(hb.hd_vehicle_count) AS avg_vehicle_cnt,
    SUM(CASE WHEN hb.hd_vehicle_count > av.avg_vehicle_cnt THEN 1 ELSE 0 END) AS households_above_avg_vehicle
FROM hb
JOIN avg_vehicle_per_band av
    ON hb.hd_income_band_sk = av.ib_income_band_sk
WHERE EXISTS (
        SELECT 1
        FROM tpcds.income_band ib2
        WHERE ib2.ib_income_band_sk = hb.hd_income_band_sk
          AND ib2.ib_upper_bound > 80000
    )
GROUP BY hb.ib_income_band_sk, hb.ib_lower_bound, hb.ib_upper_bound, hb.buy_pot_desc
ORDER BY household_cnt DESC
LIMIT 100
