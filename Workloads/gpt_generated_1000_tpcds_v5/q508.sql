WITH low_income AS (
    SELECT s.s_store_id,
           s.s_store_name,
           'Low Income' AS income_group,
           SUM(sr.sr_return_amt) AS total_return_amt,
           COUNT(*) AS return_cnt
    FROM tpcds.store_returns sr
    JOIN tpcds.household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
    WHERE ib.ib_upper_bound <= 60000
    GROUP BY s.s_store_id, s.s_store_name
    HAVING SUM(sr.sr_return_amt) > 1000
),
high_income AS (
    SELECT s.s_store_id,
           s.s_store_name,
           'High Income' AS income_group,
           SUM(sr.sr_return_amt) AS total_return_amt,
           COUNT(*) AS return_cnt
    FROM tpcds.store_returns sr
    JOIN tpcds.household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
    WHERE ib.ib_lower_bound >= 150001
    GROUP BY s.s_store_id, s.s_store_name
    HAVING SUM(sr.sr_return_amt) > 1000
)
SELECT *
FROM low_income
UNION ALL
SELECT *
FROM high_income
ORDER BY total_return_amt DESC
