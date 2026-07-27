-- Goal: Rank customers by their total web return amount for November returns, limited to customers born between 1940‑1960 and returns made in early (8 am) or afternoon (2 pm) hours. The query also flags whether a customer's total exceeds the yearly average.
WITH yearly_customer_returns AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year AS return_year,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc
        ON cc.cc_open_date_sk = d.d_date_sk
    WHERE d.d_moy = 11                                 -- filter: November
      AND c.c_birth_year BETWEEN 1940 AND 1960        -- filter: birth year range
      AND t.t_hour IN (8, 14)                         -- filter: 8 am or 2 pm returns
      AND wr.wr_return_amt > 0                        -- filter: positive return amount
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year
)
SELECT
    ycr.c_customer_sk,
    ycr.c_first_name,
    ycr.c_last_name,
    ycr.return_year,
    ycr.total_return_amt,
    ycr.return_cnt,
    RANK() OVER (PARTITION BY ycr.return_year ORDER BY ycr.total_return_amt DESC) AS yearly_rank,
    CASE
        WHEN ycr.total_return_amt > (
            SELECT AVG(total_return_amt)
            FROM yearly_customer_returns sub
            WHERE sub.return_year = ycr.return_year
        ) THEN 'ABOVE_AVG'
        ELSE 'BELOW_AVG'
    END AS performance_vs_avg
FROM yearly_customer_returns ycr
ORDER BY ycr.return_year DESC, yearly_rank
LIMIT 100
