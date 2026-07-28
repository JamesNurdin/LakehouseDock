WITH cust AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
        c.c_last_name,
        cd.cd_gender,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM customer c
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE regexp_like(c.c_email_address, '^.+@example\\..+$')
      AND c.c_last_name LIKE 'S%'
)
SELECT
    cust.email_domain,
    cust.ib_lower_bound,
    cust.ib_upper_bound,
    cust.cd_gender,
    COUNT(DISTINCT cust.c_customer_sk) AS customer_cnt,
    SUM(sr.sr_return_amt) AS total_return_amt,
    AVG(sr.sr_return_amt) AS avg_return_amt
FROM cust
JOIN store_returns sr
    ON sr.sr_customer_sk = cust.c_customer_sk
GROUP BY
    cust.email_domain,
    cust.ib_lower_bound,
    cust.ib_upper_bound,
    cust.cd_gender
ORDER BY total_return_amt DESC
LIMIT 100
