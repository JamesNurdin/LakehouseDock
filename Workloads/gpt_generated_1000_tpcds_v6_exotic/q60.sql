WITH low_income AS (
    SELECT
        td.t_hour AS hour_of_day,
        'Low Income' AS income_group,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        COUNT(*) AS returns_cnt
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    WHERE ib.ib_upper_bound <= 120000
      AND td.t_hour BETWEEN 8 AND 12
    GROUP BY td.t_hour
    HAVING COUNT(*) > 10
),
high_income AS (
    SELECT
        td.t_hour AS hour_of_day,
        'High Income' AS income_group,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        COUNT(*) AS returns_cnt
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    WHERE ib.ib_lower_bound >= 150000
      AND td.t_hour BETWEEN 8 AND 12
    GROUP BY td.t_hour
    HAVING COUNT(*) > 10
)
SELECT hour_of_day,
       income_group,
       total_return_amt,
       avg_return_amt,
       returns_cnt
FROM low_income
UNION ALL
SELECT hour_of_day,
       income_group,
       total_return_amt,
       avg_return_amt,
       returns_cnt
FROM high_income
ORDER BY income_group, hour_of_day
LIMIT 100
