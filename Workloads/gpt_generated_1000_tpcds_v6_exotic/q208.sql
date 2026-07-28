WITH return_stats AS (
    SELECT
        d.d_date AS return_date,
        d.d_year,
        d.d_quarter_seq,
        t.t_hour,
        cd.cd_gender,
        cd.cd_education_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_ship_cost) AS total_ship_cost,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer_demographics cd
        ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND d.d_quarter_seq BETWEEN 15 AND 18
      AND t.t_hour BETWEEN 9 AND 17
      AND cd.cd_gender = 'M'
      AND cd.cd_education_status = 'College'
      AND ib.ib_upper_bound >= 50000
      AND wr.wr_return_ship_cost > 20.0
    GROUP BY
        d.d_date,
        d.d_year,
        d.d_quarter_seq,
        t.t_hour,
        cd.cd_gender,
        cd.cd_education_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    AVG(total_return_amt) AS avg_return_amt,
    SUM(total_ship_cost) AS sum_ship_cost,
    COUNT(*) AS num_days
FROM return_stats
GROUP BY
    ib_lower_bound,
    ib_upper_bound
HAVING AVG(total_return_amt) > 1000
ORDER BY avg_return_amt DESC
LIMIT 100
