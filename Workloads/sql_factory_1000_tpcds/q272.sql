WITH daily_returns AS (
    SELECT
        wp.wp_web_page_id,
        d_ret.d_date,
        d_ret.d_year,
        SUM(wr.wr_return_amt) AS daily_return_amt,
        cc.cc_name,
        d_open.d_year AS cc_open_year
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN call_center cc
        ON cc.cc_open_date_sk = d_ret.d_date_sk
    LEFT JOIN date_dim d_open
        ON cc.cc_open_date_sk = d_open.d_date_sk
    WHERE d_ret.d_year = 2020
    GROUP BY wp.wp_web_page_id, d_ret.d_date, d_ret.d_year, cc.cc_name, d_open.d_year
)
SELECT
    wp_web_page_id,
    d_date,
    daily_return_amt,
    LAG(daily_return_amt) OVER (PARTITION BY wp_web_page_id ORDER BY d_date) AS prev_day_return_amt,
    daily_return_amt - LAG(daily_return_amt) OVER (PARTITION BY wp_web_page_id ORDER BY d_date) AS return_change,
    CASE
        WHEN daily_return_amt - LAG(daily_return_amt) OVER (PARTITION BY wp_web_page_id ORDER BY d_date) > 1000 THEN 'Spike'
        ELSE 'Normal'
    END AS change_flag,
    cc_name,
    cc_open_year
FROM daily_returns
ORDER BY wp_web_page_id, d_date
