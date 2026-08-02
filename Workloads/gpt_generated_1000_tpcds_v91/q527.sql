WITH sub1 AS (
    SELECT
        s.s_market_id AS market_id,
        hd.hd_income_band_sk AS income_band_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_tax) AS avg_return_tax,
        COUNT(*) AS return_cnt,
        MIN(sr.sr_return_amt) AS min_return_amt,
        MAX(sr.sr_return_amt) AS max_return_amt
    FROM
        tpcds.store_returns sr
        JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
        JOIN tpcds.household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE
        s.s_market_id IN (7, 5, 10)
        AND s.s_street_name = 'Franklin Hill'
        AND s.s_state = 'CA'
        AND hd.hd_income_band_sk = 18
        AND hd.hd_dep_count BETWEEN 2 AND 6
        AND sr.sr_store_credit > 100
    GROUP BY CUBE (s.s_market_id, hd.hd_income_band_sk)
    HAVING SUM(sr.sr_return_amt) > 500
),
sub2 AS (
    SELECT
        s.s_market_id AS market_id,
        hd.hd_income_band_sk AS income_band_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_tax) AS avg_return_tax,
        COUNT(*) AS return_cnt,
        MIN(sr.sr_return_amt) AS min_return_amt,
        MAX(sr.sr_return_amt) AS max_return_amt
    FROM
        tpcds.store_returns sr
        JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
        JOIN tpcds.household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE
        s.s_market_id IN (8, 4)
        AND s.s_street_name = 'Willow'
        AND s.s_city = 'Seattle'
        AND s.s_state = 'WA'
        AND hd.hd_income_band_sk = 8
        AND hd.hd_vehicle_count >= 2
        AND sr.sr_return_tax BETWEEN 5 AND 20
    GROUP BY CUBE (s.s_market_id, hd.hd_income_band_sk)
    HAVING AVG(sr.sr_return_tax) < 15
),
intersect_keys AS (
    SELECT market_id, income_band_sk FROM sub1
    INTERSECT
    SELECT market_id, income_band_sk FROM sub2
)
SELECT
    s1.market_id,
    s1.income_band_sk,
    s1.total_return_amt,
    s1.avg_return_tax,
    s1.return_cnt,
    s1.min_return_amt,
    s1.max_return_amt
FROM sub1 s1
JOIN intersect_keys ik
  ON s1.market_id = ik.market_id
 AND s1.income_band_sk = ik.income_band_sk
ORDER BY s1.total_return_amt DESC
LIMIT 100
