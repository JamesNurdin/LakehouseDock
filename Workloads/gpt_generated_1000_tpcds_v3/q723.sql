WITH returns AS (
    SELECT
        sr.sr_net_loss AS net_loss,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_year,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        concat(cast(ib.ib_lower_bound AS varchar), '-', cast(ib.ib_upper_bound AS varchar)) AS income_range
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.com$')
      AND substring(c.c_first_name, 1, 1) = 'J'
      AND c.c_last_name LIKE 'S%'
)
SELECT
    email_domain,
    income_range,
    SUM(net_loss) AS total_net_loss,
    COUNT(*) AS return_count
FROM returns
GROUP BY email_domain, income_range
ORDER BY total_net_loss DESC
LIMIT 100
