WITH sub_a AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_return_tax) AS avg_return_tax,
        COUNT(*) AS cnt_returns,
        MIN(wr.wr_return_amt) AS min_return_amt,
        MAX(wr.wr_return_amt) AS max_return_amt
    FROM web_returns wr
    INNER JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    INNER JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    INNER JOIN household_demographics hd_ref
        ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    INNER JOIN household_demographics hd_ret
        ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    INNER JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND t.t_am_pm = 'AM'
      AND s.s_state = 'CA'
    GROUP BY s.s_store_id, s.s_store_name, d.d_year
),
sub_b AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_return_tax) AS avg_return_tax,
        COUNT(*) AS cnt_returns,
        MIN(wr.wr_return_amt) AS min_return_amt,
        MAX(wr.wr_return_amt) AS max_return_amt
    FROM web_returns wr
    INNER JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    INNER JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    INNER JOIN household_demographics hd_ref
        ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    INNER JOIN household_demographics hd_ret
        ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    INNER JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_am_pm = 'PM'
      AND s.s_state = 'NY'
    GROUP BY s.s_store_id, s.s_store_name, d.d_year
),
combined AS (
    SELECT * FROM sub_a
    UNION ALL
    SELECT * FROM sub_b
)
SELECT
    combined.s_store_id,
    combined.s_store_name,
    combined.d_year,
    combined.total_return_amt,
    combined.avg_return_tax,
    combined.cnt_returns,
    combined.min_return_amt,
    combined.max_return_amt,
    SUM(combined.total_return_amt) OVER (PARTITION BY combined.d_year) AS year_total_return_amt,
    RANK() OVER (ORDER BY combined.total_return_amt DESC) AS return_rank
FROM combined
ORDER BY combined.total_return_amt DESC
LIMIT 100
