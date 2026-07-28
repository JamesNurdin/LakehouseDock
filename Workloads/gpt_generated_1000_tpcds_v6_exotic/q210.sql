WITH enriched AS (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        regexp_extract(c.c_email_address, '@([^.]*)', 1) AS email_domain,
        wr.wr_net_loss,
        wr.wr_return_amt
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(c.c_email_address, '\\.com$')
      AND wp.wp_url LIKE '%promo%'
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    email_domain,
    SUM(wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    AVG(wr_return_amt) AS avg_return_amt
FROM enriched
GROUP BY ib_lower_bound, ib_upper_bound, email_domain
HAVING SUM(wr_net_loss) > 10000
ORDER BY total_net_loss DESC
LIMIT 100
