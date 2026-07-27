WITH filtered_returns AS (
    SELECT
        wr.wr_return_amt,
        wr.wr_return_tax,
        cd.cd_gender,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        wp.wp_url
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(wp.wp_url, '^https?://.*promo.*$')
      AND c.c_email_address LIKE '%@example.com'
      AND cd.cd_education_status = 'College'
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    cd_gender,
    COUNT(*) AS returns_cnt,
    SUM(wr_return_amt) AS total_return_amt,
    SUM(CASE WHEN wr_return_tax > 0 THEN wr_return_tax ELSE 0 END) AS total_tax,
    COUNT(DISTINCT regexp_extract(wp_url, 'promo/([^/]+)', 1)) AS distinct_promo_codes,
    CONCAT('Band ', CAST(ib_lower_bound AS varchar), '-', CAST(ib_upper_bound AS varchar)) AS income_band_label
FROM filtered_returns
GROUP BY ib_lower_bound, ib_upper_bound, cd_gender
ORDER BY total_return_amt DESC
LIMIT 100
