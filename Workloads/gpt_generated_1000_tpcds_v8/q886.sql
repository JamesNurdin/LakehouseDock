WITH sampled_hd AS (
    SELECT *
    FROM tpcds.household_demographics
    TABLESAMPLE BERNOULLI (10)
),
filtered_hd AS (
    SELECT
        hd_demo_sk,
        hd_income_band_sk,
        hd_buy_potential,
        hd_vehicle_count,
        hd_dep_count
    FROM sampled_hd
    WHERE regexp_like(hd_buy_potential, '^\\d{1,5}-\\d{1,5}$')
      AND hd_vehicle_count >= 0
),
refund_hd AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_item_sk,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_refunded_hdemo_sk,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_vehicle_count
    FROM tpcds.web_returns wr
    JOIN filtered_hd hd
      ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE wr.wr_return_amt > 100
),
anti_filtered AS (
    SELECT *
    FROM refund_hd r
    WHERE NOT EXISTS (
        SELECT 1
        FROM tpcds.web_returns wr2
        WHERE wr2.wr_returning_hdemo_sk = r.wr_refunded_hdemo_sk
          AND wr2.wr_return_amt > 5000
    )
),
intersect_keys AS (
    SELECT hd_demo_sk FROM filtered_hd WHERE hd_buy_potential LIKE '5%-%'
    INTERSECT
    SELECT wr_refunded_hdemo_sk FROM tpcds.web_returns WHERE wr_return_amt BETWEEN 200 AND 300
),
aggregated AS (
    SELECT
        a.hd_income_band_sk,
        a.hd_buy_potential,
        COUNT(DISTINCT a.wr_return_quantity) AS distinct_return_qty,
        COUNT(DISTINCT a.hd_vehicle_count) AS distinct_vehicle_cnt,
        SUM(a.wr_return_amt) AS total_return_amt,
        SUM(
            CASE
                WHEN regexp_extract(a.hd_buy_potential, '(\\d+)-', 1) IS NOT NULL
                THEN CAST(regexp_extract(a.hd_buy_potential, '(\\d+)-', 1) AS integer)
                ELSE 0
            END
        ) AS sum_min_buy_potential
    FROM anti_filtered a
    WHERE a.hd_demo_sk IN (SELECT hd_demo_sk FROM intersect_keys)
    GROUP BY GROUPING SETS (
        (a.hd_income_band_sk, a.hd_buy_potential),
        (a.hd_income_band_sk)
    )
)
SELECT DISTINCT
    hd_income_band_sk,
    hd_buy_potential,
    distinct_return_qty,
    distinct_vehicle_cnt,
    total_return_amt,
    sum_min_buy_potential
FROM aggregated
WHERE hd_buy_potential LIKE '%-%' AND total_return_amt > 0
ORDER BY hd_income_band_sk NULLS LAST, total_return_amt DESC
LIMIT 100
