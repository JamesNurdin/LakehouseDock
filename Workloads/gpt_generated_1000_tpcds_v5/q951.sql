WITH aggregated AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        SUM(sr.sr_return_amt) AS store_return_total,
        SUM(wr.wr_return_amt) AS web_return_total,
        AVG(ib.ib_upper_bound) AS avg_income_upper_bound
    FROM store_returns sr
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN web_returns wr
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        s.s_rec_start_date > DATE '2000-01-01'
        AND s.s_street_type IN ('Road', 'Lane')
        AND wp.wp_max_ad_count >= 2
        AND ib.ib_lower_bound > 20000
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.s_city,
    a.s_state,
    a.store_return_total,
    a.web_return_total,
    a.store_return_total + a.web_return_total AS total_return_amount,
    a.avg_income_upper_bound,
    (SELECT AVG(ib2.ib_upper_bound) FROM income_band ib2) AS overall_avg_income_upper,
    ROW_NUMBER() OVER (ORDER BY (a.store_return_total + a.web_return_total) DESC) AS store_rank
FROM aggregated a
ORDER BY store_rank
LIMIT 100
