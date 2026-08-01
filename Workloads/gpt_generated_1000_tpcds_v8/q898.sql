WITH
    sampled_returns AS (
        SELECT *
        FROM web_returns TABLESAMPLE BERNOULLI (10)
    )
SELECT
    agg.c_current_hdemo_sk,
    agg.hd_income_band_sk,
    SUM(agg.return_amt) AS total_return_amt,
    COUNT(DISTINCT agg.c_customer_id) AS distinct_customers,
    COUNT(DISTINCT agg.wp_url) AS distinct_pages,
    MAX(agg.max_income_upper) AS max_income_upper_bound
FROM (
    SELECT
        c.c_customer_id,
        c.c_current_hdemo_sk,
        hd.hd_income_band_sk,
        ib.ib_upper_bound,
        wp.wp_url,
        wr.wr_return_amt_inc_tax AS return_amt,
        (SELECT max(ib2.ib_upper_bound) FROM income_band ib2) AS max_income_upper,
        lr.page_return_total
    FROM sampled_returns wr
    FULL OUTER JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c_ret
        ON wp.wp_customer_sk = c_ret.c_customer_sk
    JOIN household_demographics hd_ret
        ON c_ret.c_current_hdemo_sk = hd_ret.hd_demo_sk
    JOIN income_band ib_ret
        ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk
    JOIN LATERAL (
        SELECT SUM(wr2.wr_return_amt) AS page_return_total
        FROM web_returns wr2
        WHERE wr2.wr_web_page_sk = wp.wp_web_page_sk
    ) lr ON true
    WHERE ib.ib_upper_bound > 50000

    UNION DISTINCT

    SELECT
        c2.c_customer_id,
        c2.c_current_hdemo_sk,
        hd2.hd_income_band_sk,
        ib2.ib_upper_bound,
        wp2.wp_url,
        wr2.wr_return_amt_inc_tax AS return_amt,
        (SELECT max(ib3.ib_upper_bound) FROM income_band ib3) AS max_income_upper,
        lr2.page_return_total
    FROM sampled_returns wr2
    JOIN web_page wp2
        ON wr2.wr_web_page_sk = wp2.wp_web_page_sk
    JOIN customer c2
        ON wp2.wp_customer_sk = c2.c_customer_sk
    JOIN household_demographics hd2
        ON c2.c_current_hdemo_sk = hd2.hd_demo_sk
    JOIN income_band ib2
        ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
    JOIN household_demographics hd_ref
        ON wr2.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN income_band ib_ref
        ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
    JOIN LATERAL (
        SELECT SUM(wr3.wr_return_amt) AS page_return_total
        FROM web_returns wr3
        WHERE wr3.wr_web_page_sk = wp2.wp_web_page_sk
    ) lr2 ON true
    WHERE ib2.ib_upper_bound <= 150000
) agg
GROUP BY GROUPING SETS (
    (c_current_hdemo_sk, hd_income_band_sk),
    (c_current_hdemo_sk),
    (hd_income_band_sk)
)
ORDER BY total_return_amt DESC
LIMIT 100
