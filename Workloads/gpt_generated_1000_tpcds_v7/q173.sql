WITH customer_returns AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        wp.wp_image_count,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE wp.wp_rec_end_date > DATE '2000-01-01'
      AND ib.ib_upper_bound <= 60000
      AND c.c_birth_year BETWEEN 1960 AND 1975
      AND wp.wp_image_count >= 3
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        wp.wp_image_count
)
SELECT
    cr.c_customer_sk,
    cr.c_first_name,
    cr.c_last_name,
    cr.c_birth_year,
    cr.cd_gender,
    cr.ib_lower_bound,
    cr.ib_upper_bound,
    cr.wp_image_count,
    cr.total_return_amt,
    cr.total_return_qty,
    cr.return_cnt,
    AVG(cr.total_return_amt) OVER () AS avg_total_return_amt_overall,
    RANK() OVER (ORDER BY cr.total_return_amt DESC) AS return_rank
FROM customer_returns cr
WHERE cr.total_return_amt > (SELECT AVG(total_return_amt) FROM customer_returns)
ORDER BY cr.total_return_amt DESC
LIMIT 100
