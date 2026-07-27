WITH filtered_returns AS (
    SELECT
        wr.wr_refunded_customer_sk,
        wr.wr_web_page_sk,
        wr.wr_net_loss,
        wr.wr_return_amt,
        wp.wp_url,
        c.c_first_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE regexp_like(wp.wp_url, '^https?://.*promo.*$')
      AND regexp_like(c.c_first_name, '^[AEIOU]')
)
SELECT
    domain,
    ib_lower_bound AS income_lower,
    ib_upper_bound AS income_upper,
    COUNT(*) AS return_count,
    SUM(wr_net_loss) AS total_net_loss,
    AVG(wr_return_amt) AS avg_return_amount
FROM filtered_returns
GROUP BY domain, ib_lower_bound, ib_upper_bound
ORDER BY total_net_loss DESC
LIMIT 20
