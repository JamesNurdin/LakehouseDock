WITH sub1 AS (
    SELECT
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ARRAY[hd.hd_dep_count, hd.hd_vehicle_count] AS counts_arr
    FROM tpcds.household_demographics hd
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_buy_potential = '5001-10000'
      AND ib.ib_upper_bound > 60000
),
unrolled1 AS (
    SELECT
        s1.hd_income_band_sk,
        s1.hd_buy_potential,
        s1.ib_lower_bound,
        s1.ib_upper_bound,
        u.val AS count_value,
        u.ordinality AS count_position
    FROM sub1 s1
    CROSS JOIN UNNEST(s1.counts_arr) WITH ORDINALITY AS u(val, ordinality)
),
sub2 AS (
    SELECT
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ARRAY[hd.hd_dep_count, hd.hd_vehicle_count] AS counts_arr
    FROM tpcds.household_demographics hd
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_buy_potential = '>10000'
      AND ib.ib_lower_bound < 120000
),
unrolled2 AS (
    SELECT
        s2.hd_income_band_sk,
        s2.hd_buy_potential,
        s2.ib_lower_bound,
        s2.ib_upper_bound,
        u.val AS count_value,
        u.ordinality AS count_position
    FROM sub2 s2
    CROSS JOIN UNNEST(s2.counts_arr) WITH ORDINALITY AS u(val, ordinality)
),
unioned AS (
    SELECT * FROM unrolled1
    UNION ALL
    SELECT * FROM unrolled2
),
small_dim AS (
    SELECT * FROM (VALUES 'North', 'South') AS d(region)
)
SELECT
    u.hd_income_band_sk,
    u.hd_buy_potential,
    u.ib_lower_bound,
    u.ib_upper_bound,
    u.count_value,
    u.count_position,
    d.region
FROM unioned u
CROSS JOIN small_dim d
ORDER BY u.hd_income_band_sk, u.count_value DESC
LIMIT 100
